lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ssm_config'

Gem::Specification.new do |spec|
  spec.name          = 'ssm_config'
  spec.version       = SsmConfig::VERSION
  spec.authors       = ['Santiago Herrera']
  spec.email         = ['santiago@snapsheet.me']

  spec.summary       = 'YML file loader and parser for Rails'
  spec.homepage      = 'https://github.com/bodyshopbidsdotcom/ssm_config'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_dependency 'rails', '>= 3', '< 7'
  spec.add_development_dependency 'sqlite3', '1.4'
  spec.required_ruby_version = '>=2.6'
end
