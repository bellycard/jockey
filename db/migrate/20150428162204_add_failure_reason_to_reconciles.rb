class AddFailureReasonToReconciles < ActiveRecord::Migration
  def change
    add_column :reconciles, :failure_reason, :text
  end
end
