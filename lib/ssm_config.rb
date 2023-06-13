class SsmConfig
  VERSION = '0.1.1'.freeze
  CONFIG_PATH = 'config'.freeze
  TABLE_NAME = 'ssm_config_records'.freeze
  class << self
    def method_missing(meth, args = '')
      config_file = Rails.root.join(CONFIG_PATH, "#{meth}.yml")
      # specify certain model name?
      if ActiveRecord::Base.connection.table_exists? 'ssm_config_records'
        puts("hello")

        match_file = SsmConfigDummy.where(:file => meth.to_s)
        match_key = match_file.where('accessor_keys LIKE :prefix', :prefix => "#{args}%")

        hashes = {}

        match_key.each do |row|
          hashes[row.accessor_keys] = row.value
        end
        puts(hashes)

        hashes = hashes.sort.to_h

        reconstructed = clean_hash(reconstruct_hash(hashes))
        return access_with_hashkey(reconstructed, args)
      end
      if File.exist?(config_file)
        write_config_accessor_for(meth, args)
        send(meth)
      end
    end

    def respond_to_missing?(meth, *_args)
      config_file = Rails.root.join(CONFIG_PATH, "#{meth}.yml")
      (ActiveRecord::Base.connection.table_exists? 'ssm_config_records') || File.exist?(config_file)
    end

    private

    def reconstruct_hash(hash)
      # takes in a hash of hashes, merges them into one
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
        delimited[-1] = delimited[-1]
        if delimited[-1][0] == '['
          delimited[-1] = "#{delimited[-1]}flag"
        end
        if (curr_hash.has_key?(delimited[-1]))
          curr_hash[delimited[-1]].to_a
          curr_hash[delimited[-1]].append(value)
        else
          curr_hash[delimited[-1]] = value
        end
      end
      puts(final_hash)
      return final_hash
    end

    def clean_hash(hash)
      # takes in a hash; goes through and converts certain hashes into arrays as necessary (ie when key = [0], [1], etc)
      # such keys will be of the form '[integer]flag'
      case hash
      when Hash
        keys = hash.keys
        if (keys.size == 0)
          return hash
        end
        if (keys[0][0] == '[') && (keys[0][-4..-1] == 'flag')
          hash = hash.values
          hash.each_with_index do |element, index|
            hash[index] = clean_hash(element)
          end
        else
          hash.each do |key, value|
            hash[key] = clean_hash(value)
          end
        end
      end
      return hash
    end

    def recurse_with_hashkey(hash, key)
      # function to traverse hash according to key
      # key should be an array of keys
      if key.length.zero?
        return hash
      else
        curr = key[0]
        if curr[0] == '['
          num = curr[1..-2].to_i
          return recurse_with_hashkey(hash[num], key[1..-1])
        else
          return recurse_with_hashkey(hash[curr], key[1..-1])
        end
      end
    end

    def access_with_hashkey(hash, key)
      # wrapper function for recurse_with_hashkey, simply splits our hashkey by comma
      delimited = key.split(',')
      recurse_with_hashkey(hash, delimited)
    end

    # def parse_config_file(filename)
    #   YAML.load(ERB.new(File.read("#{Rails.root}/#{CONFIG_PATH}/#{filename}")).result).symbolize_keys
    # end

    def parse_config_file_with_env(filename, args)
      yaml_loaded = YAML.load(ERB.new(File.read("#{Rails.root}/#{CONFIG_PATH}/#{filename}")).result)
      loaded_hash = (yaml_loaded[Rails.env] || yaml_loaded['any']).try(:with_indifferent_access)

      access_with_hashkey(loaded_hash, args) || loaded_hash
    end

    def write_config_accessor_for(meth, args)
      self.instance_eval %{
        def #{meth}
          @#{meth} ||= parse_config_file_with_env('#{meth}.yml', '#{args}')
        end
      }, __FILE__, __LINE__ - 4
    end
  end
end
