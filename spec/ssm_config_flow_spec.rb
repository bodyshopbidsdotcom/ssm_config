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

  context 'when args don\'t exist' do
    before do
      SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello').save
    end

    context 'when key doesn\'t exist' do
      it 'returns from file' do
        expect(described_class.data('build')).to eq({ 'docker' => [{ 'image' => 'cimg/base:2023.03' }], 'steps' => ['checkout', { 'run' => 'echo "this is the build job"' }] })
      end
    end
  end

  context 'when there are deletions' do
    before do
      SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello').save
    end

    context 'when file is deleted from ActiveRecord' do
      it 'reverts to file' do
        SsmConfigDummy.destroy_by(:file => 'data')
        expect(described_class.data('build,docker')).to eq(['image' => 'cimg/base:2023.03'])
      end
    end

    context 'when a key is deleted from ActiveRecord' do
      it 'reverts to file' do
        SsmConfigDummy.destroy_by(:accessor_keys => 'test,[0]')
        expect(described_class.data('build,docker')).to eq(['image' => 'cimg/base:2023.03'])
      end
    end

    context 'when a value is deleted from ActiveRecord' do
      it 'reverts to file' do
        SsmConfigDummy.destroy_by(:value => 'hello')
        expect(described_class.data('build,docker')).to eq(['image' => 'cimg/base:2023.03'])
      end
    end
  end

  context 'when querying ActiveRecord gives nil' do
    context 'when querying file gives nil' do
      it 'returns default behavior' do
        expect(described_class.data2('bad_key')).to eq({ 'snapsheet' => { 'clients' => 2, 'count' => 5 }, 'snapsheet-tx' => { 'url' => 'test' } })
      end
    end

    context 'when querying file gives non-nil' do
      it 'returns correct content from file' do
        expect(described_class.data2('snapsheet,clients')).to eq(2)
      end
    end
  end
end
