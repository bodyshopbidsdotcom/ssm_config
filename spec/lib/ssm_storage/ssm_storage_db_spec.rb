# frozen_string_literal: true

require 'rails_helper'
class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe SsmConfig do
  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }
  let(:error_message) { "undefined method `non_existent' for SsmConfig:Class" }

  before do
    stub_const('SsmStorage::Yml::CONFIG_PATH', '../fixtures')
    stub_const('SsmStorage::Db::ACTIVE_RECORD_MODEL', 'SsmConfigDummy')
    run_migrations(:up, migrations_path, 1)
    SsmConfigDummy.create(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello')
    SsmConfigDummy.create(:file => 'data', :accessor_keys => 'other_key', :value => 'goodbye')
  end

  after do
    run_migrations(:down, migrations_path)
    described_class.instance_variable_set(:@data, nil)
  end

  context 'when testing queries' do
    context 'when file exists' do
      it 'returns file as hash' do
        expect(described_class.data).to eq({ 'test' => ['hello'], 'other_key' => 'goodbye' })
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when querying a file with keys' do
      it 'returns subhash properly' do
        SsmConfigDummy.create(:file => 'data', :accessor_keys => 'test,[1]', :value => 'hello2')
        expect(described_class.data[:other_key]).to eq('goodbye')
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when querying a file with array index' do
      it 'returns subhash properly' do
        expect(described_class.data[:test][0]).to eq('hello')
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when no key is specified' do
      it 'returns entire file as hash' do
        SsmConfigDummy.create(:file => 'data1', :accessor_keys => 'other', :value => 'goodbye')
        SsmConfigDummy.create(:file => 'data1', :accessor_keys => 'other2', :value => 'hello')
        expect(described_class.data1).to eq({ 'other' => 'goodbye', 'other2' => 'hello' })
      end
    end

    context 'when key gives multiple values' do
      it 'returns array properly formatted' do
        SsmConfigDummy.create(:file => 'data', :accessor_keys => 'test,[1]', :value => 'goodbye')
        expect(described_class.data[:test]).to eq(['hello', 'goodbye'])
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end
  end

  context 'when updates are made' do
    context 'when value is changed' do
      it 'returns new hash' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:value => 'goodbye')
        expect(described_class.data).to eq({ 'other_key' => 'goodbye', 'test' => ['goodbye'] })
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when key is changed' do
      it 'returns new hash' do
        SsmConfigDummy.find_by(:file => 'data', :value => 'hello').update(:accessor_keys => 'new_key')
        expect(described_class.data).to eq({ 'new_key' => 'hello', 'other_key' => 'goodbye' })
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end
  end
end
