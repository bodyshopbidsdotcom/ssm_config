# frozen_string_literal: true

require 'rails_helper'

class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe SsmConfig do
  before do
    stub_const('SsmConfig::CONFIG_PATH', '../fixtures')
    stub_const('SsmConfig::ACTIVE_RECORD_MODEL', 'SsmConfigDummy')
    run_migrations(:up, migrations_path, 1)
  end

  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }
  let(:error_message) { "undefined method `non_existent' for SsmConfig:Class" }

  after do
    run_migrations(:down, migrations_path)
  end

  context 'when table exists' do
    context 'when file exists' do
      it 'returns empty' do
        SsmConfigDummy.new(:file => 'test', :accessor_keys => 'foo', :value => 'bar').save
        expect(described_class.test).to eq({})
      end
    end

    context 'when file doesn\'t exist' do
      it 'file doesn\'t exist' do
        expect { described_class.non_existent }.to raise_error(NoMethodError).with_message(error_message)
      end
    end
  end
end
