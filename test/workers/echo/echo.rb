Havanna.connect("127.0.0.1:7711")

class Echo
  def call(job)
    Havanna.push("Echo:result", job, 5000)
  end
end
