# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "buckybox-api"
  spec.version       = "1.7.0"
  spec.authors       = ["Cédric Félizard"]
  spec.email         = ["cedric@felizard.fr"]
  spec.summary       = "RubyGem wrapper for the Bucky Box API"
  spec.description   = "#{spec.summary} - https://api.buckybox.com/docs"
  spec.homepage      = "https://github.com/buckybox/buckybox-api-ruby"
  spec.license       = "LGPLv3"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "typhoeus", ">= 1.1.0"
  spec.add_dependency "hashie", ">= 3.4.4"
  spec.add_dependency "crazy_money", ">= 1.4.0"
  spec.add_dependency "oj"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.5"
  spec.add_development_dependency "vcr", ">= 3"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "simplecov", ">= 0.11"
  spec.add_development_dependency "rubocop"
end
