# This migration comes from jockey_rds (originally 20141205000142)
class CreateJockeyRdsDatabaseInstances < ActiveRecord::Migration
  def change
    create_table :jockey_rds_database_instances do |t|
      t.string :name, null: false
      t.string :environment, null: false
      t.timestamps
    end
  end
end
