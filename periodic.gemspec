# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "periodic/version"

Gem::Specification.new do |spec|
  spec.name          = "periodic"
  spec.version       = Periodic::VERSION
  spec.authors       = ["Chris Kalafarski"]
  spec.email         = ["chris@farski.com"]

  spec.summary       = "Natural language parser and output formating for durations"
  spec.description   = "Natural language parser and output formating for durations in Ruby"
  spec.homepage      = "https://github.com/farski/periodic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '~> 1.9'

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  end

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "test-unit", "~> 3.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "coveralls", "~> 0"
  spec.add_development_dependency "rubocop", "~> 0"
  spec.add_development_dependency "shoulda-context", "~> 1.2"
end
