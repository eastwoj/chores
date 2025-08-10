class CreatePayoutNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :payout_notifications do |t|
      t.references :family, null: false, foreign_key: true
      t.references :pay_period, null: false, foreign_key: true
      t.references :adult, null: false, foreign_key: true
      t.string :title
      t.text :message
      t.datetime :read_at

      t.timestamps
    end
  end
end
