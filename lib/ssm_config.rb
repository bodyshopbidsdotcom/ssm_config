class SsmConfig
  VERSION = '0.1.1'.freeze
  CONFIG_PATH = 'config'.freeze
  TABLE_NAME = 'ssm_config_records'.freeze
  ACTIVE_RECORD_MODEL = 'SsmConfigRecord'.freeze
  class << self
    def method_missing(meth, *args, &block)
      config_file = Rails.root.join(CONFIG_PATH, "#{meth}.yml")

      if ActiveRecord::Base.connection.table_exists? TABLE_NAME
        if ACTIVE_RECORD_MODEL.constantize.exists?(:file => meth.to_s)
          return {}
        else
          super
        end
      elsif File.exist?(config_file)
        write_config_accessor_for(meth)
        send(meth)
      else
        super
      end
    end

    def respond_to_missing?(meth, *_args)
      config_file = Rails.root.join(CONFIG_PATH, "#{meth}.yml")
      File.exist?(config_file)
    end

    private

    def parse_config_file(filename)
      YAML.load(ERB.new(File.read("#{Rails.root}/#{CONFIG_PATH}/#{filename}")).result).symbolize_keys
    end

    def parse_config_file_with_env(filename)
      yaml_loaded = YAML.load(ERB.new(File.read("#{Rails.root}/#{CONFIG_PATH}/#{filename}")).result)
      (yaml_loaded[Rails.env] || yaml_loaded['any']).try(:with_indifferent_access)
    end

    def write_config_accessor_for(meth)
      self.instance_eval %{
        def #{meth}
          @#{meth} ||= parse_config_file_with_env('#{meth}.yml')
        end
      }, __FILE__, __LINE__ - 4
    end
  end
end
