# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jemal/version'

Gem::Specification.new do |spec|
  spec.name          = "jemal"
  spec.version       = Jemal::VERSION
  spec.authors       = ["oleg dashevskii"]
  spec.email         = ["olegdashevskii@gmail.com"]

  spec.summary       = %q{Interface to jemalloc}
  spec.description   = %q{Means to access jemalloc options and statistics for MRI compiled with jemalloc support.}
  spec.homepage      = "https://github.com/be9/jemal"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'ffi', '~> 1.9.10'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "log_buddy"
end
