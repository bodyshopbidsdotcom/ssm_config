require 'rails_helper'
require 'timecop'

class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe SsmConfig do
  before do
    stub_const('SsmConfig::SsmStorage::Yml::CONFIG_PATH', '../fixtures')
    stub_const('SsmConfig::SsmStorage::Db::ACTIVE_RECORD_MODEL', 'SsmConfigDummy')
    run_migrations(:up, migrations_path, 1)
    SsmConfigDummy.new(:file => 'file_name', :accessor_keys => 'test,[0]', :value => 'hullo', :datatype => 'string').save
    SsmConfigDummy.new(:file => 'file_name', :accessor_keys => 'other_key', :value => 'ciao', :datatype => 'string').save
    Timecop.freeze(Time.zone.now)
  end

  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }
  let(:error_message) { "undefined method `nonexistent' for SsmConfig:Module" }

  after do
    run_migrations(:down, migrations_path)
  end

  it 'has a version number' do
    expect(SsmConfig::VERSION).not_to be nil
  end

  describe 'flow between ActiveRecord and YAML' do
    context 'when table name doesn\'t exist' do
      it 'reads from config' do
        stub_const('SsmConfig::SsmStorage::Db::ACTIVE_RECORD_MODEL', 'SsmConfigWrong')
        expect(described_class.data2).to eq({ 'snapsheet' => { 'clients' => 2, 'count' => 5 }, 'snapsheet-tx' => { 'url' => 'test' } })
        described_class.instance_eval('undef :data2', __FILE__, __LINE__)
        described_class.instance_variable_set(:@data2, nil)
      end
    end

    context 'when file doesn\'t exist in ActiveRecord' do
      it 'returns from config' do
        expect(described_class.data2).to eq({ 'snapsheet' => { 'clients' => 2, 'count' => 5 }, 'snapsheet-tx' => { 'url' => 'test' } })
      end
    end

    context 'when file doesn\'t exist in ActiveRecord nor YAML' do
      it 'returns NoMethodError' do
        expect { described_class.nonexistent }.to raise_error(NoMethodError).with_message(error_message)
      end
    end
  end

  describe 'test caching' do
    context 'when querying a hash before refresh' do
      it 'returns same hash' do
        expect(described_class.file_name).to eq({ 'test' => ['hullo'], 'other_key' => 'ciao' })
      end
    end

    context 'when querying a hash a refresh with no update' do
      it 'returns same hash' do
        Timecop.travel(Time.zone.now + 31.minutes)
        expect(described_class.file_name).to eq({ 'test' => ['hullo'], 'other_key' => 'ciao' })
      end
    end

    context 'when testing cache is stored for multiple files' do
      it 'returns at least 2 files' do
        SsmConfigDummy.create(:file => 'second', :accessor_keys => '1', :value => '1', :datatype => 'string')
        described_class.second
        expect(described_class.last_processed_time.length).to be >= 2
      end
    end

    context 'when querying a hash before refresh with update' do
      it 'returns same hash' do
        SsmConfigDummy.find_by(:accessor_keys => 'test,[0]').update(:value => 'hullo2')
        expect(described_class.file_name).to eq({ 'test' => ['hullo'], 'other_key' => 'ciao' })
      end
    end

    context 'when querying a hash after refresh with update' do
      it 'returns updated hash' do
        SsmConfigDummy.find_by(:accessor_keys => 'test,[0]').update(:value => 'hullo2')
        Timecop.travel(Time.zone.now + 30.minutes)
        expect(described_class.file_name).to eq({ 'test' => ['hullo2'], 'other_key' => 'ciao' })
      end
    end
  end

  describe '#respond_to?' do
    context 'when testing respond_to? with existing file' do
      it 'returns true' do
        expect(described_class.respond_to?('blank')).to eq(true)
      end
    end

    context 'when testing respond_to? with nonexisting file' do
      it 'returns false' do
        expect(described_class.respond_to?('non_existent')).to eq(false)
      end
    end
  end
end
