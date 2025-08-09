class CreateChoreAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :chore_assignments do |t|
      t.references :chore, null: false, foreign_key: true
      t.references :child, null: false, foreign_key: true
      t.boolean :active

      t.timestamps
    end
  end
end
