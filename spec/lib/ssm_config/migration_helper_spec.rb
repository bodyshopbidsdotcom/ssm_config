require 'rails_helper'
class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe 'SsmStorage::MigrationHelper' do
  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }
  let(:db_query) { SsmConfig::SsmStorage::Db.new('data') }
  let(:yml_query) { SsmConfig::SsmStorage::Yml.new('data') }
  let(:db_query1) { SsmConfig::SsmStorage::Db.new('data1') }
  let(:yml_query1) { SsmConfig::SsmStorage::Yml.new('data1') }
  let(:migration_helper) { SsmConfig::MigrationHelper.new('data') }
  let(:migration_helper1) { SsmConfig::MigrationHelper.new('data1') }

  before do
    stub_const('SsmConfig::SsmStorage::Yml::CONFIG_PATH', '../fixtures')
    stub_const('SsmConfig::SsmStorage::Db::ACTIVE_RECORD_MODEL', 'SsmConfigDummy')
    run_migrations(:up, migrations_path, 1)
  end

  after do
    run_migrations(:down, migrations_path)
  end

  describe '#migrate' do
    context 'when file exists' do
      it 'migrates file correctly' do
        migration_helper1.migrate
        expect(db_query1.hash).to eq(yml_query1.hash)
      end
    end

    context 'when a more complex file exists' do
      it 'migrates file correctly' do
        migration_helper.migrate
        expect(db_query.hash).to eq(yml_query.hash)
      end
    end
  end

  describe '#unmigrate' do
    context 'when file exists in table' do
      it 'removes all instances' do
        migration_helper1.migrate
        migration_helper1.unmigrate
        expect(SsmConfigDummy.where(:file => 'data1').size).to eq(0)
      end
    end

    context 'when instances of a file already exist' do
      it 'removes all instances' do
        SsmConfigDummy.create(:file => 'data', :accessor_keys => 'to_delete', :value => '0', :datatype => 'i')
        migration_helper.unmigrate
        expect(SsmConfigDummy.where(:file => 'data').size).to eq(0)
      end
    end
  end
end
