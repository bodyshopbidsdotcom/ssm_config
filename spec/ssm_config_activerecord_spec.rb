# frozen_string_literal: true

require 'rails_helper'

class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe SsmConfig do
  before do
    stub_const('SsmConfig::CONFIG_PATH', '../fixtures')
    run_migrations(:up, migrations_path, 1)
  end

  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }

  after do
    run_migrations(:down, migrations_path)
  end

  context 'when table exists' do
    it 'returns true' do
      expect(described_class.test).to eq(true)
    end
  end
end
