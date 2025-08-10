class PayPeriod < ApplicationRecord
  belongs_to :family
  has_many :children, through: :family
  has_many :chore_completions, through: :children
  has_many :extra_completions, through: :children

  validates :frequency, presence: true, inclusion: { in: %w[weekly biweekly monthly] }
  validates :payout_day, presence: true, numericality: { in: 0..6 }
  validates :start_date, :end_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[active completed] }
  
  validate :end_date_after_start_date
  validate :only_one_current_period_per_family

  enum :status, { active: "active", completed: "completed" }

  scope :current, -> { where(current_period: true) }
  scope :for_family, ->(family) { where(family: family) }

  def self.current_for_family(family)
    for_family(family).current.first
  end

  def self.create_next_period_for_family(family)
    current_period = current_for_family(family)
    
    if current_period
      current_period.mark_as_completed!
    end

    frequency = family.family_setting.payout_frequency || "weekly"
    payout_day = family.family_setting.payout_day || 0

    if current_period && current_period.end_date
      start_date = current_period.end_date + 1.day
    else
      start_date = Date.current.beginning_of_week
    end
    end_date = calculate_end_date(start_date, frequency)

    create!(
      family: family,
      frequency: frequency,
      payout_day: payout_day,
      start_date: start_date,
      end_date: end_date,
      current_period: true,
      status: "active"
    )
  end

  def mark_as_completed!
    transaction do
      update!(status: "completed", current_period: false, last_payout_at: Time.current)
      
      # Create next period automatically
      PayPeriod.create_next_period_for_family(family)
    end
  end

  def payout_due?
    Date.current >= next_payout_date && has_completions_to_pay?
  end

  def next_payout_date
    case frequency
    when "weekly"
      end_date.next_occurring(day_of_week_name)
    when "biweekly"
      end_date + (payout_day - end_date.wday).days
    when "monthly"
      end_date.end_of_month.next_occurring(day_of_week_name)
    else
      end_date
    end
  end

  def has_completions_to_pay?
    total_earnings_for_period > 0
  end

  def total_earnings_for_period
    chore_earnings + extra_earnings
  end

  def chore_earnings
    chore_completions
      .reviewed_satisfactory
      .where(reviewed_at: start_date.beginning_of_day..end_date.end_of_day)
      .sum(:earned_amount)
  end

  def extra_earnings
    extra_completions
      .approved
      .where(approved_at: start_date.beginning_of_day..end_date.end_of_day)
      .sum(:earned_amount)
  end

  def earnings_by_child
    earnings = {}
    
    children.active.each do |child|
      child_chore_earnings = child.chore_completions
                                 .reviewed_satisfactory
                                 .where(reviewed_at: start_date.beginning_of_day..end_date.end_of_day)
                                 .sum(:earned_amount)
      
      child_extra_earnings = child.extra_completions
                                 .approved
                                 .where(approved_at: start_date.beginning_of_day..end_date.end_of_day)
                                 .sum(:earned_amount)
      
      earnings[child.id] = {
        child: child,
        chore_earnings: child_chore_earnings,
        extra_earnings: child_extra_earnings,
        total: child_chore_earnings + child_extra_earnings
      }
    end
    
    earnings
  end

  def can_payout?
    active? && all_daily_chores_completed_for_today?
  end

  def payout_blocked_reason
    return nil if can_payout?
    return "Pay period is not active" unless active?
    return "Some children have incomplete daily chores for today" unless all_daily_chores_completed_for_today?
  end

  def frequency_description
    case frequency
    when "weekly"
      "Weekly"
    when "biweekly"
      "Bi-weekly"
    when "monthly"
      "Monthly"
    else
      frequency.humanize
    end
  end

  private

  def self.calculate_end_date(start_date, frequency)
    return Date.current + 6.days if start_date.nil?
    
    case frequency
    when "weekly"
      start_date + 6.days
    when "biweekly"
      start_date + 13.days
    when "monthly"
      start_date.end_of_month
    else
      start_date + 6.days
    end
  end

  def day_of_week_name
    Date::DAYNAMES[payout_day].downcase.to_sym
  end

  def end_date_after_start_date
    return unless start_date && end_date
    
    errors.add(:end_date, "must be after start date") if end_date <= start_date
  end

  def only_one_current_period_per_family
    return unless current_period? && family

    existing = PayPeriod.where(family: family, current_period: true)
    existing = existing.where.not(id: id) if persisted?
    
    errors.add(:current_period, "can only have one current period per family") if existing.exists?
  end

  def all_daily_chores_completed_for_today?
    today = Date.current
    
    family.children.active.all? do |child|
      chore_list = child.chore_lists.find_by(start_date: today, interval: :daily)
      next true unless chore_list # No chores assigned = considered complete
      
      chore_list.chore_completions.all? { |completion| completion.completed? }
    end
  end
end