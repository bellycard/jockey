class CreateWorkers < ActiveRecord::Migration
  def change
    create_table :workers do |t|
      t.integer :scale
      t.string :command
      t.references :app, index: true
      t.references :environment, index: true

      t.timestamps
    end

    drop_table :deployed_containers
    remove_column :configured_builds, :scale
    remove_column :configured_builds, :command
    remove_column :configured_builds, :config_set_id
    add_column :configured_builds, :worker_id, :integer
  end
end
