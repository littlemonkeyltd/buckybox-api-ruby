# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "buckybox-api"
  spec.version       = "1.4.0"
  spec.authors       = ["Cédric Félizard"]
  spec.email         = ["cedric@felizard.fr"]
  spec.summary       = %q{RubyGem wrapper for the Bucky Box API}
  spec.description   = "#{spec.summary} - https://api.buckybox.com/docs"
  spec.homepage      = ""
  spec.license       = "LGPLv3"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", ">= 0.13.1"
  spec.add_dependency "super_recursive_open_struct", ">= 1.0.2"
  spec.add_dependency "crazy_money", ">= 1.2.1"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "simplecov", ">= 0.9"
end
