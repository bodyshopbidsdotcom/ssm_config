require 'spec_helper'

RSpec.describe SsmConfig do
  it 'has a version number' do
    expect(SsmConfig::VERSION).not_to be nil
  end
end
