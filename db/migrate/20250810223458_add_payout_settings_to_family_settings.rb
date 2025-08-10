class AddPayoutSettingsToFamilySettings < ActiveRecord::Migration[8.0]
  def change
    add_column :family_settings, :payout_frequency, :string, default: "weekly", null: false
    add_column :family_settings, :payout_day, :integer, default: 0, null: false
  end
end
