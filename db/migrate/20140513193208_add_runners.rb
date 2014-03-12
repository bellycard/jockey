class AddRunners < ActiveRecord::Migration
  def change
    create_table :runners do |t|
      t.references :runnable, null: false
      t.references :environment, null: false
      t.references :config_set, null: false
      t.references :build, null: false
      t.integer :scale, null: false
      t.timestamps
    end
  end
end
