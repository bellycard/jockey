class AddContainerFieldsToReconciles < ActiveRecord::Migration
  def change
    add_column :reconciles, :container_id, :string
    add_column :reconciles, :container_host, :string
  end
end
