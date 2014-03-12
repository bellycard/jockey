class AddAppToReconciles < ActiveRecord::Migration
  def change
    change_table :reconciles do |t|
      t.references :app, index: true
    end
  end
end
