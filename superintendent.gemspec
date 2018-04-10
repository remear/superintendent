# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'superintendent/version'

Gem::Specification.new do |spec|
  spec.name          = "superintendent"
  spec.version       = Superintendent::VERSION
  spec.authors       = ["Ben Mills"]
  spec.email         = ["ben@unfiniti.com"]

  spec.summary       = "Middlewares to aid in building powerful JSON API applications."
  spec.description   = "Middlewares to aid in building powerful JSON API applications."
  spec.homepage      = "https://github.com/remear/superintendent"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-configurable", "~> 0.7.0"

  spec.add_runtime_dependency 'rack', '>= 2.0.0.alpha', '< 3.0'
  spec.add_runtime_dependency 'json-schema', '~> 2.5'
  spec.add_runtime_dependency 'activesupport', '>= 5.2.0', '< 5.3'
  spec.add_runtime_dependency 'actionpack', '>= 5.2.0', '< 5.3'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency "rake", '>= 10.4', '< 12.0'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'simplecov', '~> 0.10'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'pry-byebug'
end
