class EarningsCalculator
  def initialize(child)
    @child = child
    @family_setting = @child.family.family_setting
  end

  def current_period_total
    chore_earnings + extra_earnings
  end

  def lifetime_total
    @child.chore_completions.reviewed_satisfactory.sum(:earned_amount) +
    @child.extra_completions.approved.sum(:earned_amount)
  end

  def projected_weekly_earnings
    return 0.0 unless sufficient_history?

    recent_completions = @child.chore_completions
                              .reviewed_satisfactory
                              .where("created_at > ?", 4.weeks.ago)

    return 0.0 if recent_completions.empty?

    weekly_average = recent_completions.sum(:earned_amount) / 4.0
    weekly_average.round(2)
  end

  def calculate_for_chore(chore)
    base_value = chore.base_value || @family_setting.base_chore_value
    
    # Apply difficulty multiplier
    case chore.difficulty
    when "easy"
      base_value * 1.0
    when "medium"  
      base_value * 1.5
    when "hard"
      base_value * 2.0
    else
      base_value
    end
  end

  private

  def chore_earnings
    @child.chore_completions
          .reviewed_satisfactory
          .where("reviewed_at >= ?", current_period_start)
          .sum(:earned_amount)
  end

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
    @child.chore_completions.where("created_at > ?", 4.weeks.ago).count >= 5
  end
end