class ChangeDataNextDayToAttendances < ActiveRecord::Migration[5.1]
  def change
    change_column :attendances, :next_day, :boolean, default: false
  end
end
