class CreateFamilySettings < ActiveRecord::Migration[8.0]
  def change
    create_table :family_settings do |t|
      t.references :family, null: false, foreign_key: true
      t.integer :payout_interval_days
      t.decimal :base_chore_value
      t.integer :auto_approve_after_hours
      t.text :notification_settings

      t.timestamps
    end
  end
end
