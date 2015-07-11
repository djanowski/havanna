require "cutest"
require "timeout"
require "disque"

at_exit {
  Process.waitall
}

def wait_for_pid(pid)
  wait_for { !running?(pid) }
end

def wait_for_child(pid)
  Timeout.timeout(5) do
    Process.wait(pid)
  end
end

def wait_for
  Timeout.timeout(10) do
    until value = yield
      sleep(0.1)
    end

    return value
  end
end

def running?(pid)
  begin
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end

def read_pid_file(path)
  wait_for { File.exist?(path) && File.size(path) > 0 }

  Integer(File.read(path))
end

def root(path)
  File.expand_path("../#{path}", File.dirname(__FILE__))
end

disque = Disque.new("127.0.0.1:7711")

prepare do
  disque.call("DEBUG", "FLUSHALL")
  Dir["test/workers/**/*.pid"].each { |file| File.delete(file) }
end

test "start" do
  pid = nil

  begin
    pid = spawn("#{root("bin/havanna")} start", chdir: "test/workers/echo")

    disque.push("Echo", 2, 5000)

    job = wait_for { disque.fetch(from: ["Echo:result"]) }

    assert_equal "2", job[0][-1]
  ensure
    Process.kill(:INT, pid) if pid
  end
end

test "gracefully handles TERM signals" do
  disque.push("Slow", 3, 5000)

  begin
    spawn("#{root("bin/havanna")} -d start", chdir: "test/workers/slow")

    pid = read_pid_file("./test/workers/slow/havanna.pid")

    assert wait_for { disque.call("QLEN", "Slow:result") == 0 }
  ensure
    Process.kill(:TERM, pid) if pid
  end

  wait_for_pid(pid)

  assert_equal "3", disque.fetch(from: ["Slow:result"])[0][-1]
end

test "stop waits for workers to be done" do
  spawn("#{root("bin/havanna")} start -d", chdir: "test/workers/slow")

  pid = read_pid_file("./test/workers/slow/havanna.pid")

  stopper = spawn("#{root("bin/havanna")} stop", chdir: "test/workers/slow")

  # Let the stop command start.
  wait_for { running?(stopper) }

  # Let the stop command end.
  wait_for_child(stopper)

  # Immediately after the stop command exits,
  # havanna(1) shouldn't be running and the pid file
  # should be gone.

  assert !running?(pid)
  assert !File.exist?("./test/workers/slow/havanna.pid")
end

test "use a specific path for the pid file" do
  pid = nil
  pid_path = "./test/workers/echo/foo.pid"

  begin
    spawn("#{root("bin/havanna")} -d start -p foo.pid", chdir: "test/workers/echo")

    pid = read_pid_file(pid_path)

    assert pid
  ensure
    Process.kill(:INT, pid) if pid
  end

  wait_for_pid(pid)

  assert !File.exist?(pid_path)
end

test "load Havannafile" do
  pid = nil

  begin
    pid = spawn("#{root("bin/havanna")} start", chdir: "test/workers/echo")

    disque.push("Echo", 2, 5000)

    value = wait_for { disque.fetch(from: ["Echo:result"]) }

    assert_equal "2", value
  ensure
    Process.kill(:INT, pid) if pid
  end
end

test "redirect stdout and stderr to a log file when daemonizing" do
  pid, detached_pid = nil

  pid_path = "./test/workers/logger/havanna.pid"

  log_path = "test/workers/logger/havanna.log"

  File.delete(log_path) if File.exist?(log_path)

  begin
    pid = spawn("#{root("bin/havanna")} -d start", chdir: "test/workers/logger")

    assert wait_for {
      `ps -p #{pid} -o state`.lines.to_a.last[/(\w+)/, 1] == "Z"
    }

    redis.lpush("Logger", 1)
  ensure
    detached_pid = read_pid_file(pid_path)

    Process.kill(:INT, pid) if pid
    Process.kill(:INT, detached_pid) if detached_pid
  end

  wait_for_pid(detached_pid)

  assert_equal "out: 1\nerr: 1\n", File.read(log_path)
end

test "redirect stdout and stderr to a different log file when daemonizing" do
  pid, detached_pid = nil

  pid_path = "./test/workers/logger/havanna.pid"

  log_path = "test/workers/logger/foo.log"

  File.delete(log_path) if File.exist?(log_path)

  begin
    pid = spawn("#{root("bin/havanna")} -d -l foo.log start", chdir: "test/workers/logger")

    assert wait_for {
      `ps -p #{pid} -o state`.lines.to_a.last[/(\w+)/, 1] == "Z"
    }

    redis.lpush("Logger", 1)
  ensure
    detached_pid = read_pid_file(pid_path)

    Process.kill(:INT, pid) if pid
    Process.kill(:INT, detached_pid) if detached_pid
  end

  wait_for_pid(detached_pid)

  assert_equal "out: 1\nerr: 1\n", File.read(log_path)
end

test "daemonizes" do
  pid, detached_pid = nil

  pid_path = "./test/workers/echo/havanna.pid"

  begin
    pid = spawn("#{root("bin/havanna")} -d start", chdir: "test/workers/echo")

    assert wait_for {
      `ps -p #{pid} -o state`.lines.to_a.last[/(\w+)/, 1] == "Z"
    }

    detached_pid = read_pid_file(pid_path)

    ppid = `ps -p #{detached_pid} -o ppid`.lines.to_a.last[/(\d+)/, 1]

    assert_equal "1", ppid
  ensure
    Process.kill(:INT, pid) if pid
    Process.kill(:INT, detached_pid) if detached_pid
  end

  wait_for_pid(detached_pid)

  assert !File.exist?(pid_path)
end
