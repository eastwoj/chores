class StreakCalculator
  def initialize(child)
    @child = child
  end

  def current_completion_streak
    streak = 0
    current_date = Date.current

    loop do
      list = @child.daily_chore_lists.find_by(date: current_date)
      break if list.nil?
      
      percentage = completion_percentage_for(list)
      break if percentage < 100
      
      streak += 1
      current_date -= 1.day
    end

    streak
  end

  def longest_completion_streak
    all_lists = @child.daily_chore_lists
                      .order(:date)
                      .includes(:chore_completions)
    
    return 0 if all_lists.empty?

    max_streak = 0
    current_streak = 0

    all_lists.each do |list|
      if completion_percentage_for(list) == 100
        current_streak += 1
        max_streak = [max_streak, current_streak].max
      else
        current_streak = 0
      end
    end

    max_streak
  end

  def current_bonus
    streak = current_completion_streak
    milestone_bonuses.each do |days, bonus|
      return bonus if streak >= days && (streak < next_milestone_after(days) || next_milestone_after(days).nil?)
    end
    0.0
  end

  def days_until_next_bonus
    current_streak = current_completion_streak
    next_milestone = milestone_bonuses.keys.find { |days| days > current_streak }
    return nil if next_milestone.nil?
    
    next_milestone - current_streak
  end

  def milestone_bonuses
    {
      3 => 0.50,
      7 => 1.50,
      14 => 3.50,
      30 => 8.00
    }
  end

  def streak_level
    streak = current_completion_streak
    case streak
    when 0..2
      "none"
    when 3..6
      "bronze"
    when 7..13
      "silver"
    when 14..29
      "gold"
    else
      "platinum"
    end
  end

  def is_at_milestone?
    milestone_bonuses.key?(current_completion_streak)
  end

  private

  def completion_percentage_for(list)
    return 0 if list.chore_completions.empty?
    
    completed = list.chore_completions.where(status: [:completed, :reviewed_satisfactory]).count
    total = list.chore_completions.count
    
    (completed.to_f / total * 100).round
  end

  def next_milestone_after(days)
    milestone_bonuses.keys.find { |milestone| milestone > days }
  end
end