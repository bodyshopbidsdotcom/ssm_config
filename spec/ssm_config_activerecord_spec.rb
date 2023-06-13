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
      expect(ActiveRecord::Base.connection.table_exists?('ssm_config_records')).to eq(true)
    end
  end

  context 'when testing queries' do
    before do
      SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello').save
    end

    context 'when key exists' do
      it 'returns correct value' do
        expect(described_class.data('test,[0]')).to eq('hello') # check
      end
    end

    context 'when multiple keys of same file exist' do # check when same key
      it 'returns correct value' do
        SsmConfigDummy.new(:file => 'data', :accessor_keys => 'other_key', :value => 'goodbye').save
        expect(described_class.data('other_key')).to eq('goodbye')
      end
    end

    context 'when no key is specified' do
      it 'returns all values in hash' do
        SsmConfigDummy.new(:file => 'data1', :accessor_keys => 'other', :value => 'goodbye').save
        SsmConfigDummy.new(:file => 'data1', :accessor_keys => 'other2', :value => 'hello').save
        expect(described_class.data1).to eq({ 'other' => 'goodbye', 'other2' => 'hello' })
      end
    end

    context 'when key gives multiple values' do
      it 'returns as array' do
        SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[1]', :value => 'goodbye').save
        expect(described_class.data('test')).to eq(['hello', 'goodbye'])
      end
    end
  end

  context 'when updates are made' do
    before do
      SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello').save
    end

    context 'when value is changed' do
      it 'returns updated value' do
        SsmConfigDummy.find_by(:file => 'data').update(:value => 'goodbye')
        expect(described_class.data('test,[0]')).to eq('goodbye')
      end
    end

    context 'when key is changed' do
      it 'returns updated value' do
        SsmConfigDummy.find_by(:file => 'data').update(:accessor_keys => 'new_key')
        expect(described_class.data('new_key')).to eq('hello')
      end
    end
  end
end
