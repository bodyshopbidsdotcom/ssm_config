# frozen_string_literal: true

require 'rails_helper'
require 'timecop'
class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe SsmConfig do
  before do
    stub_const('SsmStorageFile::CONFIG_PATH', '../fixtures')
    stub_const('SsmStorageDb::ACTIVE_RECORD_MODEL', 'SsmConfigDummy')
    run_migrations(:up, migrations_path, 1)
    SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello').save
    SsmConfigDummy.new(:file => 'data', :accessor_keys => 'other_key', :value => 'goodbye').save
    Timecop.freeze(Time.zone.now)
    Timecop.travel(Time.zone.now + 30.minutes)
  end

  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }

  after do
    run_migrations(:down, migrations_path)
    described_class.instance_variable_set(:@data, nil)
  end

  context 'when table exists' do
    it 'returns true' do
      expect(ActiveRecord::Base.connection.table_exists?('ssm_config_records')).to eq(true)
    end
  end

  context 'when testing queries' do
    context 'when file exists' do
      it 'returns correct value' do
        expect(described_class.data).to eq({ 'test' => ['hello'], 'other_key' => 'goodbye' })
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when querying a file with keys' do
      it 'returns correct value' do
        SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[1]', :value => 'hello2').save
        expect(described_class.data[:other_key]).to eq('goodbye')
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when querying a file with array index' do
      it 'returns correct value' do
        expect(described_class.data[:test][0]).to eq('hello')
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
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
        expect(described_class.data[:test]).to eq(['hello', 'goodbye'])
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end
  end

  context 'when updates are made' do
    context 'when value is changed' do
      it 'returns correctly' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:value => 'goodbye')
        expect(described_class.data).to eq({ 'other_key' => 'goodbye', 'test' => ['goodbye'] })
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when key is changed' do
      it 'returns correctly' do
        SsmConfigDummy.find_by(:file => 'data', :value => 'hello').update(:accessor_keys => 'new_key')
        expect(described_class.data).to eq({ 'new_key' => 'hello', 'other_key' => 'goodbye' })
        described_class.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end
  end
end
