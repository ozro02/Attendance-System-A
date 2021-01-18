class CreateApprovals < ActiveRecord::Migration[5.1]
  def change
    create_table :approvals do |t|
      t.integer :applicant_user_id
      t.integer :approval_superior_id
      t.integer :decision
      t.date :month
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
