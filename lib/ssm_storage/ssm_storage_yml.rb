module SsmStorage
  class Yml
    CONFIG_PATH = 'config'.freeze
    def initialize(file_name)
      @file_name = file_name
    end

    def file_exists?
      File.exist?(file_path)
    end

    def hash
      yaml_loaded = YAML.load(ERB.new(File.read((file_path).to_s)).result)
      (yaml_loaded[Rails.env] || yaml_loaded['any']).try(:with_indifferent_access)
    end

    private

    def file_path
      Rails.root.join(CONFIG_PATH, "#{@file_name}.yml")
    end
  end
end
