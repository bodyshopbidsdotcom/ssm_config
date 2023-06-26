module SsmStorage
  class Db
    TABLE_NAME = 'ssm_config_records'.freeze
    ACTIVE_RECORD_MODEL = 'SsmConfigRecord'.freeze
    def initialize(file_name)
      @file_name = file_name
    end

    def table_exists?
      return active_record_model_exists? if active_record_exists? && constant_exists?
      false
    end

    def hash
      match_file = ACTIVE_RECORD_MODEL.constantize.where(:file => @file_name.to_s)
      hashes = match_file.each_with_object({}) { |row, hash| hash[row.accessor_keys] = row.value; }.sort
      insert_arrays(reconstruct_hash(hashes)).try(:with_indifferent_access)
    end

    private

    def active_record_exists?
      ActiveRecord::Base.connection.table_exists? TABLE_NAME
    end

    def active_record_model_exists?
      ACTIVE_RECORD_MODEL.constantize.exists?(:file => @file_name.to_s)
    end

    def constant_exists?
      Object.const_defined? ACTIVE_RECORD_MODEL
    end

    # given a hash from hashkey (sequence of keys delimited by comma) to value, reconstruct hash
    # arrays will not be formed properly, see insert_arrays
    def reconstruct_hash(hash)
      hash.each_with_object({}) do |(key, value), final_hash| # key will represent sequence of keys needed to get down to value
        curr_hash = final_hash
        delimited = key.split(',')
        delimited[0..-2].each do |element|
          element = "#{element}flag" if element[0] == '[' # if bracket, indicates array index, add a flag indicating this is for an array index, and not some key name that had a bracket in it
          curr_hash[element] = {} unless curr_hash.key?(element) # if key doesn't exist, initialize it
          curr_hash = curr_hash[element] # move into next level of hash
        end
        delimited[-1] = "#{delimited[-1]}flag" if delimited[-1][0] == '['
        curr_hash[delimited[-1]] = value # insert value
      end
    end

    # reconstruct_hash is unable to create arrays where needed, so parse through
    # result and convert to arrays where needed
    def insert_arrays(hash)
      case hash
      when Hash
        return hash if hash.keys.size.zero? # if there are no keys, return
        if (hash.keys[0][0] == '[') && (hash.keys[0][-4..-1] == 'flag') # if key has bracket + flag, it is an array index
          hash = hash.values # convert hash to just the array of values
          hash.each_with_index do |element, index|
            hash[index] = insert_arrays(element) # recurse on each value
          end
        else # no change needed, recurse on next level of hash
          hash.each do |key, value|
            hash[key] = insert_arrays(value)
          end
        end
      end
      return hash
    end
  end
end
