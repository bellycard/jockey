class RemoveConfigVersionFromConfiguredBuilds < ActiveRecord::Migration
  def change
    remove_column :configured_builds, :config_set_version
  end
end
