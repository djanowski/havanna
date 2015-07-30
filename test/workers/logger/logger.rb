Havanna.connect("127.0.0.1:7711")

require "havanna/worker"

class Logger < Havanna::Worker
  def call(id)
    $stdout.puts("out: #{id}")
    $stderr.puts("err: #{id}")
  end
end
