# frozen_string_literal: true

require 'rails_helper'
RSpec.describe 'SsmStorage::Yml' do
  let(:yml_query) { SsmStorage::Yml.new('data') }
  let(:yml_query1) { SsmStorage::Yml.new('data1') }
  let(:yml_query_blank) { SsmStorage::Yml.new('blank') }

  before do
    stub_const('SsmStorage::Yml::CONFIG_PATH', '../fixtures')
  end

  describe '#file_exists?' do
    context 'when YAML file exists' do
      it 'file_exists? returns true' do
        expect(yml_query.file_exists?).to eq(true)
      end
    end

    context "when YAML file doesn't exist" do
      it 'raises NoMethodError' do
        expect { SsmConfig.nonexisting }.to raise_error(NoMethodError).with_message("undefined method `nonexisting' for SsmConfig:Class")
      end
    end
  end

  describe '#hash' do
    context 'when YAML file is blank' do
      let(:no_method_error_message) { "undefined method `[]' for false:FalseClass" }

      it 'raises NoMethodError' do
        expect { yml_query_blank.hash }.to raise_error(NoMethodError).with_message(no_method_error_message)
      end
    end

    context 'when YAML exists and is not blank' do
      it 'returns correct hash' do
        expect(yml_query1.hash).to eq({ 'other' => 'goodbye', 'other2' => ['hello', 'hello2'] })
      end
    end

    context 'when querying with nontrivial depth and structure' do
      it 'returns correct subhash' do
        expect(yml_query.hash[:build][:docker][0]['image']).to eq('cimg/base:2023.03')
      end
    end

    context 'when querying with a bad key' do
      it 'returns nil' do
        expect(yml_query.hash[:bad_key]).to eq(nil)
      end
    end

    context 'when both any and Rails.env are in the file' do
      it 'returns Rails.env' do
        query = SsmStorage::Yml.new('any_and_test')
        expect(query.hash).to eq({ 'days_to_enter_bank_account' => { 'default' => 2 } })
      end
    end

    context 'when only Rails.env and not any is in the file' do
      it 'returns Rails.env' do
        query = SsmStorage::Yml.new('test_only')
        expect(query.hash).to eq({ 'days_to_enter_bank_account' => { 'default' => 2 } })
      end
    end

    context 'when only any and not Rails.env is in the file' do
      it 'returns any' do
        query = SsmStorage::Yml.new('any_only')
        expect(query.hash).to eq({ 'days_to_enter_bank_account' => { 'default' => 3, 'company1' => 2 } })
      end
    end

    context 'when neither any nor Rails.env are in the file' do
      it 'returns nil' do
        query = SsmStorage::Yml.new('neither_any_nor_test')
        expect(query.hash).to eq(nil)
      end
    end
  end
end
