class AddEnvironments < ActiveRecord::Migration
  def change
    create_table :environments do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
