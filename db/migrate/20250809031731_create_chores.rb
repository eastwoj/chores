class CreateChores < ActiveRecord::Migration[8.0]
  def change
    create_table :chores do |t|
      t.string :title
      t.text :description
      t.text :instructions
      t.integer :chore_type
      t.integer :difficulty
      t.integer :estimated_minutes
      t.integer :min_age
      t.integer :max_age
      t.decimal :base_value
      t.boolean :active
      t.references :family, null: false, foreign_key: true

      t.timestamps
    end
  end
end
