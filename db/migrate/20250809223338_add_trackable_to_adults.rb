class AddTrackableToAdults < ActiveRecord::Migration[8.0]
  def change
    add_column :adults, :sign_in_count, :integer, default: 0, null: false
    add_column :adults, :current_sign_in_at, :datetime
    add_column :adults, :last_sign_in_at, :datetime
    add_column :adults, :current_sign_in_ip, :string
    add_column :adults, :last_sign_in_ip, :string
  end
end
