class RenameRunner < ActiveRecord::Migration
  def change
    rename_table :runners, :configured_builds
    remove_column :configured_builds, :runnable_id
  end
end
