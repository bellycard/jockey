class DropRunnables < ActiveRecord::Migration
  def change
    drop_table :runnables
  end
end
