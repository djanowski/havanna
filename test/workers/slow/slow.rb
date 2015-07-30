Havanna.connect("127.0.0.1:7711")

require "havanna/worker"

class Slow < Havanna::Worker
  def call(n)
    sleep(n.to_i)
    Havanna.push("Slow:result", n, 5000)
  end
end
