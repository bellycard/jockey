class AddDeletedAtToApps < ActiveRecord::Migration
  def change
    add_column :apps, :deleted_at, :datetime
    add_index :apps, :deleted_at

    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at

    add_column :environments, :deleted_at, :datetime
    add_index :environments, :deleted_at
  end
end
