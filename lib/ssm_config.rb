require './lib/ssm_storage/ssm_storage_db.rb'
require './lib/ssm_storage/ssm_storage_file.rb'
require './lib/ssm_storage/ssm_storage_empty.rb'
require 'active_support/core_ext/hash/indifferent_access'

class SsmConfig
  VERSION = '1.0.0'.freeze
  REFRESH_TIME = '30'.freeze

  class << self
    def method_missing(meth, *args, &block)
      result = populate(meth)
      super if result == false
      result
    end

    def respond_to_missing?(meth, *_args)
      config_file = Rails.root.join(SsmStorageFile::CONFIG_PATH, "#{meth}.yml")
      (ActiveRecord::Base.connection.table_exists? SsmStorageDb::TABLE_NAME) || File.exist?(config_file)
    end

    def cache
      @last_set = ActiveSupport::HashWithIndifferentAccess.new if @last_set.blank?
      @last_set
    end

    private

    def populate(meth)
      query_database = SsmStorageDb.new(meth)
      query_yml = SsmStorageFile.new(meth)
      query = nil
      if query_database.file_exists?
        query = query_database
      elsif query_yml.file_exists?
        query = query_yml
      end

      if query.present?
        self.cache[meth] = Time.zone.now
        write_config_accessor_for(meth) unless method_defined?(meth.to_sym)
        instance_variable_set("@#{meth}".to_sym, nil)
        self.send(meth, query)
      else
        false
      end
    end

    def write_config_accessor_for(meth)
      self.instance_eval %{
      def #{meth}(obj = SsmStorageEmpty.new)
        return self.send(:populate, "#{meth}") if self.cache["#{meth}".to_sym] < Time.now - REFRESH_TIME.to_i.minutes
        @#{meth} ||= obj&.hash
      end
    }, __FILE__, __LINE__ - 5
    end
  end
end
