class RenameConfiguredBuildToDeploy < ActiveRecord::Migration
  def change
    rename_table :configured_builds, :deploys
  end
end
