class AddRunnables < ActiveRecord::Migration
  def change
    create_table :runnables do |t|
      t.references :app, null: false
      t.string :command, null: false
      t.integer :port, null: false
      t.timestamps
    end
  end
end
