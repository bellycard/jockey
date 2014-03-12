class CreateDeployedContainers < ActiveRecord::Migration
  def change
    create_table :deployed_containers do |t|
      t.references :configured_build, index: true
      t.string :docker_host_ip
      t.string :container_id

      t.timestamps
    end

    change_column :configured_builds, :scale, :integer, default: 1
  end
end
