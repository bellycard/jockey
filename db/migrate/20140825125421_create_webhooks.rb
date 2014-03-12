class CreateWebhooks < ActiveRecord::Migration
  def change
    create_table :webhooks do |t|
      t.string :url
      t.string :body
      t.references :app, index: true
      t.string :type
      t.boolean :system
      t.string :room

      t.timestamps
    end
  end
end
