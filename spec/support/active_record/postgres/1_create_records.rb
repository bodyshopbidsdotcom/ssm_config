class CreateRecords < ActiveRecord::Migration[5.0]
  def self.up
    create_table :ssm_config_records do |t|
      t.column :file, :string
      t.column :accessor_keys, :string
      t.column :value, :string
      t.column :datatype, :string
    end
    add_index :ssm_config_records, :file
  end

  def self.down
    drop_table :ssm_config_records
  end
end
