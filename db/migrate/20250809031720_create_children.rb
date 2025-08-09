class CreateChildren < ActiveRecord::Migration[8.0]
  def change
    create_table :children do |t|
      t.string :first_name
      t.date :birth_date
      t.string :avatar_color
      t.boolean :active
      t.references :family, null: false, foreign_key: true

      t.timestamps
    end
  end
end
