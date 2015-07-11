Havanna.connect("127.0.0.1:7711")

class Logger
  def call(id)
    $stdout.puts("out: #{id}")
    $stderr.puts("err: #{id}")
  end
end
