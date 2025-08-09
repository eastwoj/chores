class CreateExtraAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :extra_assignments do |t|
      t.references :extra, null: false, foreign_key: true
      t.references :child, null: false, foreign_key: true
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :extra_assignments, [:extra_id, :child_id], unique: true
  end
end
