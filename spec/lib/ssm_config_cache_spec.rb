# frozen_string_literal: true

require 'rails_helper'
require 'timecop'
class SsmConfigDummy < ::ActiveRecord::Base
  self.table_name = 'ssm_config_records'
end

RSpec.describe SsmConfig do
  before do
    stub_const('SsmStorage::Yml::CONFIG_PATH', '../fixtures')
    stub_const('SsmStorage::Db::ACTIVE_RECORD_MODEL', 'SsmConfigDummy')
    run_migrations(:up, migrations_path, 1)
    SsmConfigDummy.new(:file => 'file_name', :accessor_keys => 'test,[0]', :value => 'hullo').save
    SsmConfigDummy.new(:file => 'file_name', :accessor_keys => 'other_key', :value => 'ciao').save
    Timecop.freeze(Time.zone.now)
  end

  let(:migrations_path) { SPEC_ROOT.join('support/active_record/postgres') }

  after do
    run_migrations(:down, migrations_path)
  end

  context 'when testing hashes are properly cached' do
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
  end

  context 'when testing cache is stored for multiple files' do
    it 'returns at least 2 files' do
      SsmConfigDummy.new(:file => 'second', :accessor_keys => '1', :value => '1').save
      described_class.second
      expect(described_class.last_processed_time.length).to be >= 2
    end
  end

  context 'when testing updates' do
    before do
      SsmConfigDummy.find_by(:accessor_keys => 'test,[0]').update(:value => 'hullo2')
    end

    context 'when querying a hash before refresh' do
      it 'returns same hash' do
        expect(described_class.file_name).to eq({ 'test' => ['hullo'], 'other_key' => 'ciao' })
      end
    end

    context 'when querying a hash after refresh' do
      it 'returns updated hash' do
        Timecop.travel(Time.zone.now + 30.minutes)
        expect(described_class.file_name).to eq({ 'test' => ['hullo2'], 'other_key' => 'ciao' })
      end
    end
  end
end
