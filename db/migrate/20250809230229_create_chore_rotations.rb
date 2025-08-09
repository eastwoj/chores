class CreateChoreRotations < ActiveRecord::Migration[8.0]
  def change
    create_table :chore_rotations do |t|
      t.references :chore, null: false, foreign_key: true
      t.references :child, null: false, foreign_key: true
      t.date :assigned_date

      t.timestamps
    end

    add_index :chore_rotations, [:chore_id, :assigned_date]
    add_index :chore_rotations, [:child_id, :assigned_date]
    add_index :chore_rotations, [:chore_id, :child_id, :assigned_date], unique: true
  end
end
