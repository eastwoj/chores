class CreateExtras < ActiveRecord::Migration[8.0]
  def change
    create_table :extras do |t|
      t.string :title
      t.text :description
      t.decimal :reward_amount
      t.date :available_from
      t.date :available_until
      t.integer :max_completions
      t.boolean :active
      t.references :family, null: false, foreign_key: true

      t.timestamps
    end
  end
end
