class FamilySetting < ApplicationRecord
  belongs_to :family

  validates :payout_interval_days, presence: true, numericality: { greater_than: 0 }
  validates :base_chore_value, presence: true, numericality: { greater_than: 0 }
  validates :auto_approve_after_hours, presence: true, numericality: { greater_than: 0 }
  validates :payout_frequency, presence: true, inclusion: { in: %w[weekly biweekly monthly] }
  validates :payout_day, presence: true, numericality: { in: 0..6 }

  def auto_approve_enabled?
    auto_approve_after_hours > 0
  end

  def next_payout_date
    # This would need to be calculated based on family's last payout
    # For now, return next occurrence based on interval
    case payout_interval_days
    when 7
      Date.current.beginning_of_week + 1.week
    when 14
      Date.current.beginning_of_week + 2.weeks  
    when 30
      Date.current.beginning_of_month + 1.month
    else
      Date.current + payout_interval_days.days
    end
  end

  def payout_frequency_description
    case payout_frequency
    when "weekly"
      "Weekly"
    when "biweekly"
      "Bi-weekly"
    when "monthly"
      "Monthly"
    else
      payout_frequency.humanize
    end
  end

  def payout_day_name
    Date::DAYNAMES[payout_day]
  end
end
