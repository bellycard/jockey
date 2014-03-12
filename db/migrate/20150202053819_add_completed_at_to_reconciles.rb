class AddCompletedAtToReconciles < ActiveRecord::Migration
  def change
    add_column :reconciles, :completed_at, :datetime
  end
end
