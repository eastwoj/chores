class CompletionPercentageCalculator
  def initialize(chore_list)
    @daily_chore_list = chore_list  # Keep same instance var name for now to avoid breaking tests
  end

  def calculate
    return 0 if total_chores.zero?
    
    (completed_chores.to_f / total_chores * 100).round
  end

  private

  def completed_chores
    @daily_chore_list.chore_completions.where(status: [:completed, :reviewed_satisfactory]).count
  end

  def total_chores
    @daily_chore_list.chore_completions.count
  end
end