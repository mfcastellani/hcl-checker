lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hcl/checker/version'

Gem::Specification.new do |spec|
  spec.name          = 'hcl-checker'
  spec.version       = HCL::Checker::VERSION
  spec.authors       = ['Marcelo Castellani']
  spec.email         = ['marcelo.castellani@totvs.com.br']

  spec.summary       = 'Hashicorp Configuration Language parser for Ruby'
  spec.description   = 'This gem cam parse HCL version 1 and checks if syntax is ok.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
