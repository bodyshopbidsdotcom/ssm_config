require 'bundler/setup'
require 'ssm_config'
require 'byebug'
require 'ssm_config_spec_helpers'
require 'support/active_record/models'

SPEC_ROOT = Pathname.new(File.expand_path('../', __FILE__))

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.include SsmConfigSpecHelpers
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
