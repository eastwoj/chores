class ProgressCalculator
  def initialize(child)
    @child = child
  end

  def weekly_completion_rate
    lists = @child.chore_lists
                  .where("start_date >= ?", 7.days.ago.to_date)
                  .where(interval: :daily)
                  .includes(:chore_completions)
    
    return 0.0 if lists.empty?

    total_percentage = lists.map { |list| completion_percentage_for(list) }.sum
    (total_percentage / lists.count.to_f).round(2)
  end

  def monthly_completion_rate
    lists = @child.chore_lists
                  .where("start_date >= ?", 30.days.ago.to_date)
                  .where(interval: :daily)
                  .includes(:chore_completions)
    
    return 0.0 if lists.empty?

    total_percentage = lists.map { |list| completion_percentage_for(list) }.sum
    (total_percentage / lists.count.to_f).round(2)
  end

  def completion_trend
    recent_rate = weekly_completion_rate
    historical_rate = @child.chore_lists
                           .where("start_date >= ? AND start_date < ?", 14.days.ago.to_date, 7.days.ago.to_date)
                           .where(interval: :daily)
                           .includes(:chore_completions)
                           .map { |list| completion_percentage_for(list) }
                           .then { |percentages| percentages.empty? ? 0 : percentages.sum / percentages.count.to_f }

    difference = recent_rate - historical_rate

    if difference > 5
      "improving"
    elsif difference < -5
      "declining"
    else
      "stable"
    end
  end

  def completion_streak
    streak = 0
    current_date = Date.current

    loop do
      list = @child.chore_lists.find_by(start_date: current_date, interval: :daily)
      break if list.nil?
      
      percentage = completion_percentage_for(list)
      break if percentage < 100
      
      streak += 1
      current_date -= 1.day
    end

    streak
  end

  def best_day_percentage
    @child.chore_lists
          .where(interval: :daily)
          .includes(:chore_completions)
          .map { |list| completion_percentage_for(list) }
          .max || 0
  end

  def average_chores_per_day(days = 7)
    lists = @child.chore_lists
                  .where("start_date >= ?", days.days.ago.to_date)
                  .where(interval: :daily)
                  .includes(:chore_completions)
    
    return 0.0 if lists.empty?

    total_chores = lists.sum { |list| list.chore_completions.count }
    total_chores.to_f / lists.count
  end

  private

  def completion_percentage_for(list)
    return 0 if list.chore_completions.empty?
    
    completed = list.chore_completions.where(status: [:completed, :reviewed_satisfactory]).count
    total = list.chore_completions.count
    
    (completed.to_f / total * 100).round
  end
end