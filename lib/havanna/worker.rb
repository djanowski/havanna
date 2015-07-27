module Havanna
  class Worker
    def self.to_h
      {name => new.method(:call)}
    end
  end
end
