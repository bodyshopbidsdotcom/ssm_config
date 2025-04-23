require_relative 'lib/ssm_config/version'

Gem::Specification.new do |spec|
  spec.name          = 'ssm_config'
  spec.version       = SsmConfig::VERSION
  spec.authors       = ['Santiago Herrera']
  spec.email         = ['santiago@snapsheet.me']

  spec.summary       = 'YML file loader and parser for Rails'
  spec.homepage      = 'https://github.com/bodyshopbidsdotcom/ssm_config'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['github_repo'] = 'https://github.com/bodyshopbidsdotcom/ssm_config'
    spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/bodyshopbidsdotcom'
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

  spec.add_development_dependency 'bundler', '>= 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails'
  spec.add_dependency 'rails', '>= 3', '< 8'
  spec.add_development_dependency 'sqlite3', '~> 1.6'
  spec.required_ruby_version = '>=2.7'
end
