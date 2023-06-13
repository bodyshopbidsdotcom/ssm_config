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

  context 'when testing queries' do
    before do
      SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello').save
    end

    context 'when key exists' do
      it 'returns correct value' do
        expect(described_class.data('test,[0]')).to eq({"test" => ["hello"]}) # check
      end
    end

    context 'when key doesn\'t exist' do
      it 'returns empty hash' do
        expect(described_class.data('bad_key')).to eq({})
      end
    end

    context 'when multiple keys of same file exist' do # check when same key
      it 'returns correct value' do
        SsmConfigDummy.new(:file => 'data', :accessor_keys => 'other_key', :value => 'goodbye').save
        expect(described_class.data('other_key')).to eq({"other_key" => "goodbye"})
      end
    end

    context 'when no key is specified' do
      it 'returns all values in hash' do
        SsmConfigDummy.new(:file => 'data1', :accessor_keys => 'other', :value => 'goodbye').save
        SsmConfigDummy.new(:file => 'data1', :accessor_keys => 'other2', :value => 'hello').save
        expect(described_class.data1).to eq({"other" => 'goodbye', 'other2' => 'hello'})
      end
    end

    context 'when file doesn\'t exist' do
      it 'returns empty' do
        expect(described_class.non_existing('data')).to eq({})
      end
    end

    context 'when file doesn\'t exist and no key' do
      it 'returns empty' do
        expect(described_class.non_existing).to eq({})
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
        expect(described_class.data('test,[0]')).to eq({"test" => ['goodbye']})
      end
    end

    context 'when key is changed' do
      it 'returns updated value' do
        SsmConfigDummy.find_by(:file => 'data').update(:accessor_keys => 'new_key')
        expect(described_class.data('new_key')).to eq({"new_key" => 'hello'})
      end
    end
  end
  # deletion

  context 'when there are deletions' do
    before do
      SsmConfigDummy.new(:file => 'data', :accessor_keys => 'test,[0]', :value => 'hello').save
    end
    
    context 'when file is deleted' do
      it 'returns empty' do
        SsmConfigDummy.destroy_by(file: 'data')
        expect(described_class.data('test,[0]')).to eq({})
      end
    end

    context 'when a key is deleted' do
      it 'returns empty' do
        SsmConfigDummy.destroy_by(accessor_keys: 'test,[0]')
        expect(described_class.data('test,[0]')).to eq({})
      end
    end

    context 'when a value is deleted' do
      it 'returns empty' do
        SsmConfigDummy.destroy_by(value: 'hello')
        expect(described_class.data('test,[0]')).to eq({})
      end
    end
  end
end
