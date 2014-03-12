class AddNameToWorker < ActiveRecord::Migration
  def change
    add_column :workers, :name, :string
  end
end
