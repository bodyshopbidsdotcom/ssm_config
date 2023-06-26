# frozen_string_literal: true

require 'rails_helper'
class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe 'SsmStorage::Db' do
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
    SsmConfig.instance_variable_set(:@data, nil)
  end

  describe '#file_exists?' do
    let(:db_query) { SsmStorage::Db.new('data') }

    context 'when file doesn\'t exist' do
      it 'file_exists? returns false' do
        query = SsmStorage::Db.new('non_existent')
        expect(query.file_exists?).to eq(false)
      end
    end

    context 'when ActiveRecordModel doesn\'t exist' do
      it 'file_exists? returns false' do
        stub_const('SsmStorage::Db::ACTIVE_RECORD_MODEL', 'SsmConfigWrong')
        expect(db_query.file_exists?).to eq(false)
      end
    end
  end

  describe '#hash' do
    context 'when querying a file with keys' do
      it 'returns subhash properly' do
        expect(SsmConfig.data[:other_key]).to eq('goodbye')
        SsmConfig.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when querying a file with array index' do
      it 'returns subhash properly' do
        expect(SsmConfig.data[:test][0]).to eq('hello')
        SsmConfig.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when no key is specified' do
      it 'returns entire file as hash' do
        SsmConfigDummy.create(:file => 'data1', :accessor_keys => 'other', :value => 'goodbye')
        SsmConfigDummy.create(:file => 'data1', :accessor_keys => 'other2', :value => 'hello')
        expect(SsmConfig.data1).to eq({ 'other' => 'goodbye', 'other2' => 'hello' })
      end
    end

    context 'when key gives multiple values' do
      it 'returns array properly formatted' do
        SsmConfigDummy.create(:file => 'data', :accessor_keys => 'test,[1]', :value => 'goodbye')
        expect(SsmConfig.data[:test]).to eq(['hello', 'goodbye'])
        SsmConfig.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end
  end

  context 'when updates are made' do
    context 'when value is changed' do
      it 'returns new hash' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:value => 'goodbye')
        expect(SsmConfig.data).to eq({ 'other_key' => 'goodbye', 'test' => ['goodbye'] })
        SsmConfig.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end

    context 'when key is changed' do
      it 'returns new hash' do
        SsmConfigDummy.find_by(:file => 'data', :value => 'hello').update(:accessor_keys => 'new_key')
        expect(SsmConfig.data).to eq({ 'new_key' => 'hello', 'other_key' => 'goodbye' })
        SsmConfig.instance_eval('undef :data', __FILE__, __LINE__)
      end
    end
  end
end
