module SsmConfig
  class MigrationHelper
    def initialize(file_name)
      @file_name = file_name
      @model_name = SsmConfig::SsmStorage::Db::ACTIVE_RECORD_MODEL
    end

    def up
      added = []
      keys_hash = accessor_key_hash(hash) # starting layer is always hash
      last = nil
      keys_hash.each do |accessor_key, value|
        last = accessor_key
        added.push(@model_name.constantize.create!(:file => @file_name, :accessor_keys => accessor_key, :value => value.to_s, :datatype => determine_class(value)))
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("#{e.message} was raised because of faulty data with accessor_key #{last}")
      added.each(&:delete)
    end

    def down
      @model_name.constantize.where(:file => @file_name).destroy_all
    end

    private

    def accessor_key_recurse(value, curr, res)
      case value
      when Hash
        res.merge!(accessor_key_hash(value, curr))
      when Array
        res.merge!(accessor_key_array(value, curr))
      else
        res[curr[1..-1]] = value
      end
    end

    def accessor_key_hash(hash, curr = '')
      hash.each_with_object({}) do |(key, value), res|
        updated_hash = "#{curr},#{key}"
        accessor_key_recurse(value, updated_hash, res)
      end
    end

    def accessor_key_array(arr, curr = '')
      arr.each_with_object({}).with_index do |(value, res), index|
        updated_hash = "#{curr},[#{index}]"
        accessor_key_recurse(value, updated_hash, res)
      end
    end

    def erb?(value)
      (value[0..2] == '<%=') && (value[-2..-1] == '%>')
    end

    def determine_class(value)
      return 'boolean' if (value == false) || (value == true)
      return value.class unless value.is_a? String
      erb?(value) ? 'erb' : 'string'
    end

    def file_path
      Rails.root.join(SsmConfig::SsmStorage::Yml::CONFIG_PATH, "#{@file_name}.yml")
    end

    def hash
      yaml_loaded = if Psych::VERSION > '4.0'
        YAML.safe_load(File.read((file_path).to_s), aliases: true)
      else
        YAML.load(File.read((file_path).to_s))
      end
      (yaml_loaded[Rails.env] || yaml_loaded['any']).try(:with_indifferent_access)
    end
  end
end
