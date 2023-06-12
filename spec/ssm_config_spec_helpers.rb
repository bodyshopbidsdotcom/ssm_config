module SsmConfigSpecHelpers
  def run_migrations(direction, migrations_paths, target_version = nil)
    if rails_below?('5.2.0.rc1')
      ActiveRecord::Migrator.send(direction, migrations_paths, target_version)
    elsif rails_below?('6.0.0.rc1')
      ActiveRecord::MigrationContext.new(migrations_paths).send(direction, target_version)
    else
      ActiveRecord::MigrationContext.new(migrations_paths, ActiveRecord::SchemaMigration).send(direction, target_version)
    end
  end

  def rails_below?(rails_version)
    Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new(rails_version)
  end
end
