lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hcl/checker/version'

Gem::Specification.new do |spec|
  spec.name          = 'hcl-checker'
  spec.version       = HCL::Checker::VERSION
  spec.authors       = ['Marcelo Castellani']
  spec.email         = ['marcelofc.rock@gmail.com']

  spec.summary       = 'Hashicorp Configuration Language parser for Ruby'
  spec.description   = 'Hashicorp Configuration Language parser and checker for Ruby'
  spec.homepage      = 'https://github.com/mfcastellani/hcl-checker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0.2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'racc', '1.4.14'
  spec.add_development_dependency 'rex', '2.0.12'
  spec.add_development_dependency 'rexical', '>= 1.0.7'

end
