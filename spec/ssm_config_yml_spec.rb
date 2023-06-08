# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SsmConfig do
  before do
    stub_const('SsmConfig::CONFIG_PATH', '../fixtures')
  end

  context 'when YAML file exists and is blank' do
    let(:no_method_error_message) { "undefined method `[]' for false:FalseClass" }

    context 'with 0 depth' do
      it 'raises NoMethodError' do
        expect { described_class.blank }.to raise_error(NoMethodError).with_message(no_method_error_message)
      end
    end

    context 'with nontrivial depth' do
      it 'raises NoMethodError' do
        expect { described_class.blank[:key][0] }.to raise_error(NoMethodError).with_message(no_method_error_message)
      end
    end
  end

  context 'when YAML file exists and is not blank' do
    context 'with 0 depth' do
      it 'returns correctly' do
        expect(described_class.data2).to eq({ 'snapsheet' => { 'clients' => 2, 'count' => 5 }, 'snapsheet-tx' => { 'url' => 'test' } })
      end
    end

    context 'with nontrivial depth and structure' do
      it 'returns correctly' do
        expect(described_class.data[:build][:docker][0]['image']).to eq('cimg/base:2023.03')
      end
    end

    context 'with a bad key' do
      it 'returns nil' do
        expect(described_class.data[:bad_key]).to eq(nil)
      end
    end
  end

  context "when YAML file doesn't exist" do
    it 'raises NoMethodError' do
      expect { described_class.nonexisting }.to raise_error(NoMethodError).with_message("undefined method `nonexisting' for SsmConfig:Class")
    end
  end

  context 'when testing environments' do
    context 'when both any and Rails.env are in the file' do
      it 'returns Rails.env' do
        expect(described_class.any_and_test).to eq({ 'days_to_enter_bank_account' => { 'default' => 2 } })
      end
    end

    context 'when only Rails.env and not any is in the file' do
      it 'returns Rails.env' do
        expect(described_class.test_only).to eq({ 'days_to_enter_bank_account' => { 'default' => 2 } })
      end
    end

    context 'when only any and not Rails.env is in the file' do
      it 'returns any' do
        expect(described_class.any_only).to eq({ 'days_to_enter_bank_account' => { 'default' => 3, 'company1' => 2 } })
      end
    end

    context 'when neither any nor Rails.env are in the file' do
      it 'returns nil' do
        expect(described_class.neither_any_nor_test).to eq(nil)
      end
    end
  end

  context 'when specifying the environment' do
    context 'when selecting any' do
      it 'returns nil' do
        expect(described_class.data[:any]).to eq(nil)
      end
    end

    context 'when selecting Rails.env' do
      it 'returns nil' do
        expect(described_class.test_only[:test]).to eq(nil)
      end
    end

    context 'when selecting a different environment in the yml file' do
      it 'returns nil' do
        expect(described_class.data[:workflows]).to eq(nil)
      end
    end
  end

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
