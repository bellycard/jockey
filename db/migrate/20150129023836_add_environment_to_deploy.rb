class AddEnvironmentToDeploy < ActiveRecord::Migration
  def change
    change_table :deploys do |t|
      t.references :environment, null: false
    end
  end
end
