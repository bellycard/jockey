class RemoveDefaultFromBuildStatus < ActiveRecord::Migration
  def change
    change_column :builds, :status, :integer, default: nil, null: true
  end
end
