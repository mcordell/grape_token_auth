# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grape_token_auth/version'

Gem::Specification.new do |spec|
  spec.name          = 'grape_token_auth'
  spec.version       = GrapeTokenAuth::VERSION
  spec.authors       = ['Michael Cordell']
  spec.email         = ['surpher@gmail.com']

  spec.summary       = %q{Token auth for grape apps}
  spec.homepage      = 'https://github.com/mcordell/grape_token_auth'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'grape', '~> 0.13.0'
  spec.add_dependency 'warden', '~> 1.2.3'
  spec.add_dependency 'bcrypt', '~> 3.0'
  spec.add_dependency 'mail',   '~> 2.0'
  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'omniauth'
  spec.add_development_dependency 'omniauth-facebook'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'timecop'
end
