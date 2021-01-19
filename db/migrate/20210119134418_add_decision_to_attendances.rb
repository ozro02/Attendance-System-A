class AddDecisionToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :decision, :string
  end
end
