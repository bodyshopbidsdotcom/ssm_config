class SsmConfig
  VERSION = "0.0.1"

  class << self

    def method_missing(meth, *args, &block)
      config_file = Rails.root.join('config', "#{meth}.yml")

      if File.exists?(config_file)
        write_config_accessor_for(meth)
        self.send(meth)
      else
        super
      end
    end

    private

    def parse_config_file(filename)
      YAML.load(ERB.new(File.read("#{Rails.root}/config/#{filename}")).result).symbolize_keys
    end

    def parse_config_file_with_env(filename)
      yaml_loaded = YAML.load(ERB.new(File.read("#{Rails.root}/config/#{filename}")).result)
      (yaml_loaded[Rails.env] || yaml_loaded['any']).try(:with_indifferent_access)
    end

    def write_config_accessor_for(meth)
      self.instance_eval %Q{
        def #{meth}
          @#{meth} ||= parse_config_file_with_env('#{meth}.yml')
        end
      }
    end

  end
end
