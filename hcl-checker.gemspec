lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hcl/checker/version'

Gem::Specification.new do |spec|
  spec.name          = 'hcl-checker'
  spec.version       = HCL::Checker::VERSION
  spec.authors       = ['Marcelo Castellani']
  spec.email         = ['marcelo@linux.com']

  spec.summary       = 'Hashicorp Configuration Language parser for Ruby'
  spec.description   = 'Hashicorp Configuration Language parser and checker for Ruby'
  spec.homepage      = 'https://github.com/mfcastellani/hcl-checker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.1.4'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'racc', '1.5.0'
  spec.add_development_dependency 'rex', '2.0.12'
  spec.add_development_dependency 'rexical', '>= 1.0.7'

  spec.post_install_message = %q{
Hello, I am updating this Gem to support version 2.0 of the HCL.

In the meantime, it is important that you know that there will be a
compatibility break with the current version, for Gem to support both
versions.

Therefore, instead of using just HCL::Checker you must tell which
version you are using, like this:

HCL1::Checker

Or

HCL2::Checker

At the moment both HCL::Checker and HCL1::Checker will work, but with
the release of support for version 2 the HCL::Checker syntax will no
longer work.

So, update your code.

Thank you :)
}
end
