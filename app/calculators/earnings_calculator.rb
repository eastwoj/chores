class EarningsCalculator
  def initialize(child)
    @child = child
    @family_setting = @child.family.family_setting
  end

  def current_period_total
    extra_earnings
  end

  def lifetime_total
    @child.extra_completions.approved.sum(:earned_amount)
  end

  def projected_weekly_earnings
    return 0.0 unless sufficient_history?

    recent_completions = @child.extra_completions
                              .approved
                              .where("created_at > ?", 4.weeks.ago)

    return 0.0 if recent_completions.empty?

    weekly_average = recent_completions.sum(:earned_amount) / 4.0
    weekly_average.round(2)
  end

  private


  def extra_earnings
    @child.extra_completions
          .approved
          .where("approved_at >= ?", current_period_start)
          .sum(:earned_amount)
  end

  def current_period_start
    @current_period_start ||= calculate_period_start
  end

  def calculate_period_start
    interval = @family_setting.payout_interval_days
    
    case interval
    when 7
      Date.current.beginning_of_week
    when 14
      weeks_since_epoch = Date.current.cweek
      if weeks_since_epoch.even?
        Date.current.beginning_of_week
      else
        Date.current.beginning_of_week - 1.week
      end
    when 30
      Date.current.beginning_of_month
    else
      Date.current - interval.days
    end
  end

  def sufficient_history?
    @child.extra_completions.where("created_at > ?", 4.weeks.ago).count >= 5
  end
end