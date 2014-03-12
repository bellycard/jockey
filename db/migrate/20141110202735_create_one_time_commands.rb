class CreateOneTimeCommands < ActiveRecord::Migration
  def change
    create_table :one_time_commands do |t|
      t.references :app, index: true
      t.references :environment, index: true
      t.string :command
      t.string :rref
      t.string :state
      t.string :callback_url
      t.text :output, limit: 4294967295
      t.integer :timeout

      t.timestamps
    end
  end
end
