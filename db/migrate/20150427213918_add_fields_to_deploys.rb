class AddFieldsToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :completed_at, :datetime
    add_column :deploys, :failure_reason, :text
  end
end
