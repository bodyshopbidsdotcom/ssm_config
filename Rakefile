require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  # Only load the dummy Rails app when running tests
  require File.expand_path('../spec/rails_app/config/application', __FILE__)
end

task default: :spec
