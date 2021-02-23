class AddChangeRequestToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :change_request, :string
  end
end
