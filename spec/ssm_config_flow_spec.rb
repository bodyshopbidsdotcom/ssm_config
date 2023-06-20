# frozen_string_literal: true

require 'rails_helper'

class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe SsmConfig do
  before do
    stub_const('SsmStorageFile::CONFIG_PATH', '../fixtures')
    stub_const('SsmStorageDb::ACTIVE_RECORD_MODEL', 'SsmConfigDummy')
    run_migrations(:up, migrations_path, 1)
    SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello').save
  end

  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }
  let(:error_message) { "undefined method `nonexistent' for SsmConfig:Class" }

  after do
    run_migrations(:down, migrations_path)
  end

  context 'when file doesn\'t exist in ActiveRecord' do
    it 'returns from YAML' do
      expect(described_class.data2).to eq({ 'snapsheet' => { 'clients' => 2, 'count' => 5 }, 'snapsheet-tx' => { 'url' => 'test' } })
    end
  end

  context 'when file doesn\'t exist in ActiveRecord nor YAML' do
    it 'returns NoMethodError' do
      expect { described_class.nonexistent }.to raise_error(NoMethodError).with_message(error_message)
    end
  end
end
