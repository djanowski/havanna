require_relative "lib/havanna"

Gem::Specification.new do |s|
  s.name     = "havanna"
  s.version  = Havanna::VERSION
  s.summary  = "Ruby workers for Disque."
  s.authors  = ["Damian Janowski"]
  s.email    = ["damian.janowski@gmail.com"]
  s.homepage = "https://github.com/djanowski/havanna"

  s.files = `git ls-files`.split("\n")

  s.executables << "havanna"

  s.add_dependency "disque"
  s.add_dependency "clap"

  s.add_development_dependency "cutest"
end
