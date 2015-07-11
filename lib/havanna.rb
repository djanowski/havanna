require "disque"

module Havanna
  VERSION = "1.0.0"

  def self.connect(*args)
    @connect = args
    @disque = Disque.new(*args)
  end

  def self.start(worker)
    instance = worker.new

    begin
      disque = Disque.new(*@connect)

      printf("Started worker %s\n", worker)

      loop do
        disque.fetch(from: [worker.name], timeout: 5000) do |job|
          instance.call(job)
        end

        break if @stop
      end
    ensure
      disque.quit
    end
  end

  def self.push(*args)
    @disque.push(*args)
  end

  def self.stop
    @stop = true
  end
end
