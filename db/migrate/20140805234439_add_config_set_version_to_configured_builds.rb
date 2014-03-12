class AddConfigSetVersionToConfiguredBuilds < ActiveRecord::Migration
  def change
    add_column :configured_builds, :config_set_version, :integer
    add_column :configured_builds, :state, :string
  end
end
