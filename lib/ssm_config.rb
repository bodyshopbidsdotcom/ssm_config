require 'ssm_config/ssm_storage/db.rb'
require 'ssm_config/ssm_storage/yml.rb'
require 'ssm_config/ssm_storage/empty.rb'
require 'ssm_config/errors.rb'
require 'ssm_config/migration_helper.rb'
require 'active_support/all'

module SsmConfig
  VERSION = '1.3.4'.freeze
  REFRESH_TIME = (30.minutes).freeze

  class << self
    def method_missing(meth, *args, &block)
      result = populate(meth)
      super if result == false
      result
    end

    def respond_to_missing?(meth, *_args)
      determine_query(meth).present?
    end

    def last_processed_time
      @last_processed_time ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    private

    def determine_query(meth)
      query_database = SsmConfig::SsmStorage::Db.new(meth)
      query_yml = SsmConfig::SsmStorage::Yml.new(meth)
      return query_database if query_database.table_exists?
      return query_yml if query_yml.file_exists?
      nil
    end

    def populate(meth)
      query = determine_query(meth)

      return false if query.blank?
      self.last_processed_time[meth] = Time.zone.now
      write_config_accessor_for(meth) unless method_defined?(meth.to_sym)
      instance_variable_set("@#{meth}".to_sym, nil)
      self.send(meth, query)
    end

    def write_config_accessor_for(meth)
      self.instance_eval %{
      def #{meth}(obj = SsmConfig::SsmStorage::Empty.new)
        return self.send(:populate, "#{meth}") if self.last_processed_time["#{meth}".to_sym] < Time.zone.now - REFRESH_TIME
        @#{meth} ||= obj&.hash
      end
    }, __FILE__, __LINE__ - 5
    end
  end
end
