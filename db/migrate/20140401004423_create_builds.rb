class CreateBuilds < ActiveRecord::Migration
  def change
    create_table :builds do |t|
      t.references :app, null: false, index: true
      t.string :ref, null: false
      t.integer :status, default: 0, null: false
      t.string :callback_url
      t.datetime :completed_at
      t.timestamps
    end
  end
end
