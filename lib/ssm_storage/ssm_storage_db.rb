module SsmStorage
  class Db
    TABLE_NAME = 'ssm_config_records'.freeze
    ACTIVE_RECORD_MODEL = 'SsmConfigRecord'.freeze
    def initialize(file_name)
      @file_name = file_name
    end

    def file_exists?
      active_record_exists = ActiveRecord::Base.connection.table_exists? TABLE_NAME
      if active_record_exists && (Object.const_defined? ACTIVE_RECORD_MODEL)
        ACTIVE_RECORD_MODEL.constantize.exists?(:file => @file_name.to_s)
      else
        false
      end
    end

    def hash
      match_file = ACTIVE_RECORD_MODEL.constantize.where(:file => @file_name.to_s)
      hashes = {}
      match_file.each do |row|
        hashes[row.accessor_keys] = row.value
      end
      hashes = hashes.sort.to_h
      insert_arrays(reconstruct_hash(hashes)).try(:with_indifferent_access)
    end

    private

    # given a hash from hashkey (sequence of keys delimited by comma) to value, reconstruct hash
    # arrays will not be formed properly, see insert_arrays
    def reconstruct_hash(hash)
      final_hash = {} # initialize hash
      hash.each do |key, value| # key will represent sequence of keys needed to get down to value
        curr_hash = final_hash
        delimited = key.split(',') # hashkeys are the keys separated by commas, so delimit them
        delimited[0..-2].each do |element| # go until -2, then handle -1 separately since this is when we insert the value
          if element[0] == '[' # if bracket, indicates array index
            element = "#{element}flag" # add a flag indicating this is for an array index, and not some key name that had a bracket in it
          end
          unless curr_hash.key?(element)
            curr_hash[element] = {} # if key doesn't exist, initialize it
          end
          curr_hash = curr_hash[element] # move into next level of hash
        end
        if delimited[-1][0] == '['
          delimited[-1] = "#{delimited[-1]}flag"
        end
        curr_hash[delimited[-1]] = value # insert value
      end
      return final_hash
    end

    # reconstruct_hash is unable to create arrays where needed, so parse through
    # result and convert to arrays where needed
    def insert_arrays(hash)
      case hash
      when Hash
        keys = hash.keys
        if keys.size.zero? # if there are no keys, return
          return hash
        end
        if (keys[0][0] == '[') && (keys[0][-4..-1] == 'flag') # if key has bracket + flag, it is an array index
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
