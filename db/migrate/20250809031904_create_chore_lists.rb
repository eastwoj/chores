class CreateChoreLists < ActiveRecord::Migration[8.0]
  def change
    create_table :chore_lists do |t|
      t.references :child, null: false, foreign_key: true
      t.integer :interval, null: false, default: 0
      t.date :start_date, null: false
      t.datetime :generated_at

      t.timestamps null: false
    end

    add_index :chore_lists, [:child_id, :start_date, :interval], 
              unique: true, 
              name: "index_unique_chore_list_per_child_date_interval"
    add_index :chore_lists, :start_date
  end
end
