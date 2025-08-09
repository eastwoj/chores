class CreateExtraCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :extra_completions do |t|
      t.references :child, null: false, foreign_key: true
      t.references :extra, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :completed_at
      t.datetime :approved_at
      t.references :approved_by, null: true, foreign_key: { to_table: :adults }
      t.decimal :earned_amount, precision: 8, scale: 2, default: 0.0
      t.text :notes

      t.timestamps null: false
    end

    add_index :extra_completions, [:child_id, :status]
    add_index :extra_completions, :completed_at
    add_index :extra_completions, :approved_at
  end
end
