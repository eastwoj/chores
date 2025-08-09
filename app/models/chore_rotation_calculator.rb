class ChoreRotationCalculator
  def initialize(chore, eligible_children)
    @chore = chore
    @eligible_children = eligible_children
  end

  def next_child_for_assignment(date)
    return @eligible_children.first if @eligible_children.one?

    child_with_least_recent_assignment(date)
  end

  private

  def child_with_least_recent_assignment(date)
    # Look back 30 days to find the most fair assignment
    lookback_period = 30.days.ago..date

    assignment_counts = calculate_assignment_counts(lookback_period)
    
    # Find children with the minimum assignment count
    min_count = assignment_counts.values.min
    least_assigned_children = assignment_counts.select { |_, count| count == min_count }.keys

    # Among those, pick the one who was assigned this chore longest ago
    select_child_by_recency(least_assigned_children, date)
  end

  def calculate_assignment_counts(period)
    counts = Hash.new(0)
    
    @eligible_children.each { |child| counts[child] = 0 }
    
    @chore.chore_rotations
          .joins(:child)
          .where(assigned_date: period, child: @eligible_children)
          .group(:child)
          .count
          .each { |child, count| counts[child] = count }

    counts
  end

  def select_child_by_recency(children, date)
    return children.first if children.one?

    # Find who was assigned this chore longest ago
    most_recent_assignments = @chore.chore_rotations
                                   .where(child: children)
                                   .group(:child)
                                   .maximum(:assigned_date)

    # Pick child with oldest (or no) assignment
    children.min_by { |child| most_recent_assignments[child] || Date.new(1900, 1, 1) }
  end
end