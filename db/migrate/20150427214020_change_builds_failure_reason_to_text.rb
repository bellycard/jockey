class ChangeBuildsFailureReasonToText < ActiveRecord::Migration
  def up
    change_column :builds, :failure_reason, :text
  end
  def down
    change_column :builds, :failure_reason, :string
  end
end
