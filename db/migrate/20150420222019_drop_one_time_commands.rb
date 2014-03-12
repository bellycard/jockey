class DropOneTimeCommands < ActiveRecord::Migration
  def change
    drop_table :one_time_commands
  end
end
