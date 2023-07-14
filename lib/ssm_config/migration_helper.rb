module SsmConfig
  class MigrationHelper
    def initialize(file_name)
      @file_name = file_name
      @model_name = SsmConfig::SsmStorage::Db::ACTIVE_RECORD_MODEL
    end

    def migrate
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

    def unmigrate
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

    def determine_class(value)
      return 'boolean' if (value == false) || (value == true)
      return value.class
    end

    def hash
      SsmConfig::SsmStorage::Yml.new(@file_name).hash
    end
  end
end
