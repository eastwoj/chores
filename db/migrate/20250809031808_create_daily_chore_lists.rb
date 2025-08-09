class CreateDailyChoreLists < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_chore_lists do |t|
      t.references :child, null: false, foreign_key: true
      t.date :date
      t.datetime :generated_at

      t.timestamps
    end
  end
end
