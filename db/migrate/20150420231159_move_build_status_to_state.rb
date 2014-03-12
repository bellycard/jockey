class MoveBuildStatusToState < ActiveRecord::Migration
  def change
    add_column :builds, :state, :string
    execute "UPDATE builds SET state='in_progress' WHERE status = 0"
    execute "UPDATE builds SET state='completed' WHERE status = 1"
    execute "UPDATE builds SET state='failed' WHERE status = 2"
    remove_column :builds, :status
  end
end
