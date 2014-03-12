class AddRrefToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :rref, :string
  end
end
