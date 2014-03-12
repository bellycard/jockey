class AddContainerToBuild < ActiveRecord::Migration
  def change
    change_table :builds do |t|
      t.column :container_host, :string
      t.column :container_id, :string
    end
  end
end
