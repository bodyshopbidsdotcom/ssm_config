class SsmStorageDb
  TABLE_NAME = 'ssm_config_records'.freeze
  ACTIVE_RECORD_MODEL = 'SsmConfigRecord'.freeze
  def initialize(file_name)
    @file_name = file_name
  end

  def file_exists?
    active_record_exists = ActiveRecord::Base.connection.table_exists? TABLE_NAME
    if active_record_exists and (defined? (ACTIVE_RECORD_MODEL.constantize) == 'constant')
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

  def reconstruct_hash(hash)
    final_hash = {}
    hash.each do |key, value|
      curr_hash = final_hash
      delimited = key.split(',')
      delimited[0..-2].each_with_index do |element, _index|
        if element[0] == '['
          element = "#{element}flag"
        end
        unless curr_hash.key?(element)
          curr_hash[element] = {}
        end
        curr_hash = curr_hash[element]
      end
      if delimited[-1][0] == '['
        delimited[-1] = "#{delimited[-1]}flag"
      end
      if curr_hash.key?(delimited[-1])
        curr_hash[delimited[-1]].to_a
        curr_hash[delimited[-1]].append(value)
      else
        curr_hash[delimited[-1]] = value
      end
    end
    return final_hash
  end

  def insert_arrays(hash)
    case hash
    when Hash
      keys = hash.keys
      if keys.size.zero?
        return hash
      end
      if (keys[0][0] == '[') && (keys[0][-4..-1] == 'flag')
        hash = hash.values
        hash.each_with_index do |element, index|
          hash[index] = insert_arrays(element)
        end
      else
        hash.each do |key, value|
          hash[key] = insert_arrays(value)
        end
      end
    end
    return hash
  end
end
