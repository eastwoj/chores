class ChoreRotationGenerator
  def initialize(family, date = Date.current)
    @family = family
    @date = date
    @children = family.children.active
  end

  def generate_rotational_assignments
    return {} if @children.empty?

    rotational_chores = @family.chores.active.rotational
    assignments = {}
    daily_assignment_counts = Hash.new(0) # Track assignments within this day

    # Sort chores by difficulty to distribute load more evenly
    sorted_chores = rotational_chores.sort_by(&:difficulty_weight)

    sorted_chores.each do |chore|
      eligible_children = find_eligible_children(chore)
      next if eligible_children.empty?

      assigned_child = select_child_for_rotation(chore, eligible_children, daily_assignment_counts)
      assignments[assigned_child] ||= []
      assignments[assigned_child] << chore
      daily_assignment_counts[assigned_child] += chore.difficulty_weight

      record_rotation(chore, assigned_child)
    end

    assignments
  end

  private

  def find_eligible_children(chore)
    @children.select { |child| chore.age_appropriate_for?(child) }
  end

  def select_child_for_rotation(chore, eligible_children, daily_assignment_counts)
    # For better daily balance, consider both historical data and current day's assignments
    
    # If only one eligible child, assign to them
    return eligible_children.first if eligible_children.one?
    
    # Find children with the least workload today (by difficulty weight)
    min_daily_weight = daily_assignment_counts.values_at(*eligible_children).min || 0
    least_loaded_children = eligible_children.select do |child|
      (daily_assignment_counts[child] || 0) == min_daily_weight
    end
    
    # Among those with least daily load, use historical rotation logic
    if least_loaded_children.size == 1
      least_loaded_children.first
    else
      rotation_calculator = ChoreRotationCalculator.new(chore, least_loaded_children)
      rotation_calculator.next_child_for_assignment(@date)
    end
  end

  def record_rotation(chore, child)
    ChoreRotation.create!(
      chore: chore,
      child: child,
      assigned_date: @date
    )
  end
end