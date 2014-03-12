class AlterRunnables < ActiveRecord::Migration
  def change
    change_column :runnables, :command, :string, null: true
    change_column :runnables, :port, :integer, null: true
  end
end
