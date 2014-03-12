class AddConfigSets < ActiveRecord::Migration
  def change
    create_table :config_sets do |t|
      t.text :config, null: false, limit: 4294967295
      t.references :app, null: false
      t.references :environment, null: false
      t.timestamps
    end
  end
end
