source 'https://rubygems.org'

# Specify your gem's dependencies in ssm_config.gemspec
gemspec

gem 'mysql2'

group :development, :test do
  gem 'pry-byebug'
  gem 'rubocop', '~> 0.92', :require => false
  gem 'rubocop-rails', :require => false
  gem 'rubocop-rspec', :require => false
  gem 'timecop'
end

source 'https://rubygems.pkg.github.com/bodyshopbidsdotcom' do
  group :development do
    gem 'snap-style'
  end
end
