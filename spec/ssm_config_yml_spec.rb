require 'rails_helper'

RSpec.describe SsmConfig do # do, when, it, expect
  before do
    stub_const('SsmConfig::CONFIG_PATH', '../fixtures')
  end

  context 'When a YAML file exists' do
    context 'when YAML file is blank' do
      let(:no_method_error_message) { "undefined method `[]' for false:FalseClass" }

      context 'with 0 depth' do
        it 'raises NoMethodError' do
          expect { SsmConfig.blank }.to raise_error(NoMethodError).with_message(no_method_error_message)
        end
      end

      context 'with nontrivial depth' do
        it 'raises NoMethodError' do
          expect { SsmConfig.blank }.to raise_error(NoMethodError).with_message(no_method_error_message)
        end
      end

      context 'with Rails.env as key' do
        it 'raises NoMethodError' do
          expect { SsmConfig.blank }.to raise_error(NoMethodError).with_message(no_method_error_message)
        end
      end

      context 'with any as key' do
        it 'raises NoMethodError' do
          expect { SsmConfig.blank }.to raise_error(NoMethodError).with_message(no_method_error_message)
        end
      end
    end

    context 'when YAML file is not blank' do
      context 'with 0 depth' do
        it 'returns correctly' do
          expect(SsmConfig.data2).to eq({ 'snapsheet' => { 'clients' => 2, 'transactions' => 5 },
                                          'snapsheet-tx' => { 'clients' => 3, 'description' => 'test',
                                                              'transactions' => 1 } })
        end
      end

      context 'with nontrivial depth and structure' do
        it 'returns correctly' do
          expect(SsmConfig.data[:build][:docker][0]['image']).to eq('cimg/base:2023.03')
        end
      end

      context 'with a bad key' do
        it 'returns nil' do
          expect(SsmConfig.data[:bad_key]).to eq(nil)
        end
      end
    end
  end

  context 'When no YAML is specified' do
    it 'returns SsmConfig' do
      expect(SsmConfig).to eq(SsmConfig)
    end
  end

  context "When YAML file doesn't exist" do
    it 'raises NoMethodError' do
      expect do
        SsmConfig.nonexisting
      end.to raise_error(NoMethodError).with_message("undefined method `nonexisting' for SsmConfig:Class")
    end
  end

  context 'When testing environments' do
    context 'when both any and Rails.env are in the file' do
      it 'returns Rails.env' do
        expect(SsmConfig.any_and_test).to eq({ 'days_to_enter_bank_account' => { 'default' => 2 } })
      end
    end

    context 'when only Rails.env and not any is in the file' do
      it 'returns Rails.env' do
        expect(SsmConfig.test_only).to eq({ 'days_to_enter_bank_account' => { 'default' => 2 } })
      end
    end

    context 'when only any and not Rails.env is in the file' do
      it 'returns any' do
        expect(SsmConfig.any_only).to eq({ 'days_to_enter_bank_account' => { 'default' => 3, 'company1' => 2,
                                                                             'company2' => 4 } })
      end
    end

    context 'when neither any nor Rails.env are in the file' do
      it 'returns nil' do
        expect(SsmConfig.neither_any_nor_test).to eq(nil)
      end
    end

    context 'When specifying the environment' do
      context 'when selecting any' do
        it 'returns nil' do
          expect(SsmConfig.data[:any]).to eq(nil)
        end
      end

      context 'when selecting Rails.env' do
        it 'returns nil' do
          expect(SsmConfig.test_only[:test]).to eq(nil)
        end
      end

      context 'when selecting a different environment in the yml file' do
        it 'returns nil' do
          expect(SsmConfig.data[:workflows]).to eq(nil)
        end
      end
    end
  end
end
