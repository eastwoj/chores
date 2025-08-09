class CreateAdultRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :adult_roles do |t|
      t.references :adult, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :adult_roles, [:adult_id, :role_id], unique: true
  end
end
