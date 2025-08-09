class CreateChoreCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :chore_completions do |t|
      t.references :chore_list, null: false, foreign_key: true
      t.references :chore, null: false, foreign_key: true
      t.references :child, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :completed_at
      t.datetime :reviewed_at
      t.references :reviewed_by, null: true, foreign_key: { to_table: :adults }
      t.text :review_notes
      t.decimal :earned_amount, precision: 8, scale: 2, default: 0.0

      t.timestamps null: false
    end

    add_index :chore_completions, [:child_id, :created_at]
    add_index :chore_completions, :status
    add_index :chore_completions, :completed_at
  end
end
