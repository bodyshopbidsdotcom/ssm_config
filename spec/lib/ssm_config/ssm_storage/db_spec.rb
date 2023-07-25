require 'rails_helper'
class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe 'SsmStorage::Db' do
  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }
  let(:error_message) { "undefined method `non_existent' for SsmConfig:Class" }
  let(:invalid_datatype_message) { 'Not a valid class: must be one of string, integer, boolean, or float' }
  let(:invalid_boolean_message) { 'Not a valid boolean: must be one of true or false' }
  let(:db_query) { SsmConfig::SsmStorage::Db.new('data') }
  let(:db_query2) { SsmConfig::SsmStorage::Db.new('data1') }

  before do
    stub_const('SsmConfig::SsmStorage::Yml::CONFIG_PATH', '../fixtures')
    stub_const('SsmConfig::SsmStorage::Db::ACTIVE_RECORD_MODEL', 'SsmConfigDummy')
    run_migrations(:up, migrations_path, 1)
    SsmConfigDummy.create(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello', :datatype => 'string')
    SsmConfigDummy.create(:file => 'data', :accessor_keys => 'other_key', :value => 'goodbye', :datatype => 'string')
  end

  after do
    run_migrations(:down, migrations_path)
  end

  describe '#table_exists?' do
    context 'when database doesn\'t exist' do
      it 'returns false' do
        query = SsmConfig::SsmStorage::Db.new('non_existent')
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_raise.and_return(ActiveRecord::NoDatabaseError)
        expect(query.table_exists?).to eq(false)
      end
    end

    context 'when Mysql2 doesn\'t exist' do
      it 'returns false' do
        query = SsmConfig::SsmStorage::Db.new('non_existent')
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_raise.and_return(Mysql2::Error::ConnectionError)
        expect(query.table_exists?).to eq(false)
      end
    end

    context 'when file doesn\'t exist' do
      it 'table_exists? returns false' do
        query = SsmConfig::SsmStorage::Db.new('non_existent')
        expect(query.table_exists?).to eq(false)
      end
    end

    context 'when ActiveRecordModel doesn\'t exist' do
      it 'table_exists? returns false' do
        stub_const('SsmConfig::SsmStorage::Db::ACTIVE_RECORD_MODEL', 'SsmConfigWrong')
        expect(db_query.table_exists?).to eq(false)
      end
    end
  end

  describe '#hash' do
    context 'when querying a file with keys' do
      it 'returns subhash properly' do
        expect(db_query.hash[:other_key]).to eq('goodbye')
      end
    end

    context 'when querying a file with array index' do
      it 'returns subhash properly' do
        expect(db_query.hash[:test][0]).to eq('hello')
      end
    end

    context 'when no key is specified' do
      it 'returns entire file as hash' do
        SsmConfigDummy.create(:file => 'data1', :accessor_keys => 'other', :value => 'goodbye', :datatype => 'string')
        SsmConfigDummy.create(:file => 'data1', :accessor_keys => 'other2,[0]', :value => 'hello', :datatype => 'string')
        SsmConfigDummy.create(:file => 'data1', :accessor_keys => 'other2,[1]', :value => 'hello2', :datatype => 'string')
        expect(db_query2.hash).to eq({ 'other' => 'goodbye', 'other2' => ['hello', 'hello2'] })
      end
    end

    context 'when key gives multiple values' do
      it 'returns array properly formatted' do
        SsmConfigDummy.create(:file => 'data', :accessor_keys => 'test,[1]', :value => 'goodbye', :datatype => 'string')
        expect(db_query.hash[:test]).to eq(['hello', 'goodbye'])
      end
    end
  end

  describe 'datatype' do
    context 'when datatype is integer' do
      it 'returns integer' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:value => '3')
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:datatype => 'integer')
        expect(db_query.hash[:test][0]).to eq(3)
      end
    end

    context 'when datatype is boolean' do
      it 'returns boolean' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:value => 'True')
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:datatype => 'Boolean')
        expect(db_query.hash[:test][0]).to eq(true)
      end
    end

    context 'when boolean is invalid' do
      it 'raises error' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:value => 'invalid boolean')
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:datatype => 'Boolean')
        expect { db_query.hash[:test][0] }.to raise_error(SsmConfig::InvalidBoolean).with_message(invalid_boolean_message)
      end
    end

    context 'when datatype is float' do
      it 'returns float' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:value => '0.1')
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:datatype => 'float')
        expect(db_query.hash[:test][0]).to eq(0.1)
      end
    end

    context 'when datatype is ERB' do
      it 'returns evaluated expression' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:value => "<%= ENV['VAR'] || 'val' %>")
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:datatype => 'erb')
        expect(db_query.hash[:test][0]).to eq('val')
      end
    end

    context 'when datatype is invalid' do
      it 'raises error' do
        SsmConfigDummy.find_by(:file => 'data', :accessor_keys => 'test,[0]').update(:datatype => 'char_invalid')
        expect { db_query.hash[:test][0] }.to raise_error(SsmConfig::UnsupportedDatatype).with_message(invalid_datatype_message)
      end
    end
  end
end
