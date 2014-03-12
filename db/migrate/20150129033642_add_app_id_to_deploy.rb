class AddAppIdToDeploy < ActiveRecord::Migration
  def change
    change_table :deploys do |t|
      t.references :app, null: false
    end
  end
end
