class CreateFamilies < ActiveRecord::Migration[8.0]
  def change
    create_table :families do |t|
      t.string :name, null: false, limit: 100

      t.timestamps null: false
    end

    add_index :families, :name
  end
end
