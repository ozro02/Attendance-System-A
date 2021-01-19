class RenameDecisionColumnToAttendances < ActiveRecord::Migration[5.1]
  def change
    rename_column :attendances, :decision, :request
  end
end
