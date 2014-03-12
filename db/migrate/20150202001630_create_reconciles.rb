class CreateReconciles < ActiveRecord::Migration
  def change
    create_table :reconciles do |t|
      t.references :environment, index: true
      t.string :state
      t.string :callback_url
      t.text :plan, limit: 4294967295
      t.timestamps
    end
  end
end
