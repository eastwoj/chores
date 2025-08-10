class CreatePayPeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :pay_periods do |t|
      t.references :family, null: false, foreign_key: true
      t.string :frequency, null: false
      t.integer :payout_day
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, default: "active", null: false
      t.datetime :last_payout_at
      t.boolean :current_period, default: false, null: false

      t.timestamps
    end

    add_index :pay_periods, [:family_id, :current_period], unique: true, where: "current_period = true"
    add_index :pay_periods, [:family_id, :status]
    add_index :pay_periods, [:start_date, :end_date]
  end
end
