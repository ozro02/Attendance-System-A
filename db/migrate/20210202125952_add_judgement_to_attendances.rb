class AddJudgementToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :judgement, :string
  end
end
