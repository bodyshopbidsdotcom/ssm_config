require './lib/ssm_storage/ssm_storage_db.rb'
require './lib/ssm_storage/ssm_storage_yml.rb'
require './lib/ssm_storage/ssm_storage_empty.rb'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/time'

class SsmConfig
  VERSION = '1.0.0'.freeze
  REFRESH_TIME = (30.minutes).freeze

  class << self
    def method_missing(meth, *args, &block)
      result = populate(meth)
      super if result == false
      result
    end

    def respond_to_missing?(meth, *_args)
      config_file = Rails.root.join(SsmStorage::Yml::CONFIG_PATH, "#{meth}.yml")
      (ActiveRecord::Base.connection.table_exists? SsmStorage::Db::TABLE_NAME) || File.exist?(config_file)
    end

    def last_processed_time
      @last_processed_time ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    private

    def determine_query(meth)
      query_database = SsmStorage::Db.new(meth)
      query_yml = SsmStorage::Yml.new(meth)
      return query_database if query_database.file_exists?
      return query_yml if query_yml.file_exists?
      nil
    end

    def populate(meth)
      query = determine_query(meth)

      if query.present?
        self.last_processed_time[meth] = Time.zone.now
        write_config_accessor_for(meth) unless method_defined?(meth.to_sym)
        instance_variable_set("@#{meth}".to_sym, nil)
        self.send(meth, query)
      else
        false
      end
    end

    def write_config_accessor_for(meth)
      self.instance_eval %{
      def #{meth}(obj = SsmStorage::Empty.new)
        return self.send(:populate, "#{meth}") if self.last_processed_time["#{meth}".to_sym] < Time.now - REFRESH_TIME
        @#{meth} ||= obj&.hash
      end
    }, __FILE__, __LINE__ - 5
    end
  end
end
