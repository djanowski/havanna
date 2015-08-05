require "disque"

module Havanna
  VERSION = "1.1.0"

  def self.connect(*args)
    @connect = args
    @disque = Disque.new(*args)
  end

  def self.start(name, handler)
    begin
      disque = Disque.new(*@connect)

      printf("Started worker %s\n", name)

      loop do
        disque.fetch(from: [name], timeout: 5000) do |job|
          handler.call(job)
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
