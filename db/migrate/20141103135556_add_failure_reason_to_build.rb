class AddFailureReasonToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :failure_reason, :string
  end
end
