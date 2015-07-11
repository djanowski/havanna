Havanna.connect("127.0.0.1:7711")

class Slow
  def call(n)
    sleep(n.to_i)
    Havanna.push("Slow:result", n, 5000)
  end
end
