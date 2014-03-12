class RemoveEnvFromConfiguredBuilds < ActiveRecord::Migration
  def change
    remove_column :configured_builds, :environment_id
    add_column :configured_builds, :command, :string
  end
end
