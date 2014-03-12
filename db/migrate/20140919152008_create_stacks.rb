class CreateStacks < ActiveRecord::Migration
  def change
    create_table :stacks do |t|
      t.string :name
    end
    add_column :apps, :stack_id, :integer
    add_index :apps, :stack_id
  end
end
