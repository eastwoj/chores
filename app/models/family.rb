class Family < ApplicationRecord
  has_many :adults, dependent: :destroy
  has_many :children, dependent: :destroy
  has_many :chores, dependent: :destroy
  has_many :extras, dependent: :destroy
  has_many :daily_chore_lists, through: :children
  has_one :family_setting, dependent: :destroy
  has_many :pay_periods, dependent: :destroy
  has_many :payout_notifications, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }

  after_create :create_default_family_setting

  def active_children
    children.where(active: true)
  end

  def inactive_children
    children.where(active: false)
  end

  def generate_daily_chore_lists(date = Date.current)
    DailyChoreListGenerator.new(self, date).generate_for_all_children
  end

  def current_pay_period
    pay_periods.current.first || ensure_current_pay_period
  end

  def ensure_current_pay_period
    PayPeriod.create_next_period_for_family(self)
  end

  private

  def create_default_family_setting
    create_family_setting!(
      payout_interval_days: 7,
      base_chore_value: 0.50,
      auto_approve_after_hours: 48,
      payout_frequency: "weekly",
      payout_day: 0,
      require_chores_for_extras: false
    )
  end
end