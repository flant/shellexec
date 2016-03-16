lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shellfold/version'

Gem::Specification.new do |spec|
  spec.name          = "shellfold"
  spec.version       = Shellfold::VERSION
  spec.authors       = ["flant"]
  spec.email         = ["256@flant.com"]
  spec.summary       = "Run shell commands and fold output gently"
  spec.description   = "#{spec.summary}."
  spec.license       = "MIT"
  spec.homepage      = "https://github.com/flant/shellfold"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.2.1'

  spec.add_dependency "mixlib-shellout", ">= 2.2.6", "< 3.0"

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4', '>= 3.4.0'
  spec.add_development_dependency 'pry', '>= 0.10.3', '< 1.0'
  spec.add_development_dependency 'travis', '~> 1.8', '>= 1.8.2'
end
