class CreateChildRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :child_roles do |t|
      t.references :child, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :child_roles, [:child_id, :role_id], unique: true
  end
end
