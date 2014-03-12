class AddContainerToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :container_host, :string
    add_column :deploys, :container_id, :string
  end
end
