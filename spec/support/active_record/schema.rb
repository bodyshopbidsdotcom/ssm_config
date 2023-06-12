require 'active_record'
require 'logger'

begin
  if ActiveRecord.version >= Gem::Version.new('6.1.0')
    db_config = ActiveRecord::Base.configurations.configs_for(:env_name => Rails.env).first
    ActiveRecord::Tasks::DatabaseTasks.create(db_config)
  else
    db_config = ActiveRecord::Base.configurations[Rails.env].clone
    db_type = db_config['adapter']
    db_name = db_config.delete('database')
    raise StandardError, 'No database name specified.' if db_name.blank?
    if db_type == 'sqlite3'
      db_file = Pathname.new(__FILE__).dirname.join(db_name)
      db_file.unlink if db_file.file?
    else
      if defined?(JRUBY_VERSION)
        db_config.symbolize_keys!
        db_config[:configure_connection] = false
      end
      adapter = ActiveRecord::Base.send("#{db_type}_connection", db_config)
      adapter.recreate_database db_name, db_config.slice('charset').symbolize_keys
      adapter.disconnect!
    end
  end
rescue StandardError => e
  Kernel.warn e
end

logfile = Pathname.new(__FILE__).dirname.join('debug.log')
logfile.unlink if logfile.file?
ActiveRecord::Base.verbose_query_logs = true

ActiveRecord::Base.logger = Logger.new(logfile)

ActiveRecord::Migration.verbose = false

ActiveRecord::Base.establish_connection(YAML.safe_load(File.read('./spec/rails_app/config/database.yml'))['test'])

ActiveRecord::Schema.define do
  create_table :ssm_config_records do |t|
    t.column :file, :string
    t.column :accessor_keys, :string
    t.column :value, :string
  end
end
