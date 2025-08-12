class ChoreRotationGenerator
  def initialize(family, date = Date.current)
    @family = family
    @date = date
    @active_children = family.children.active
  end

  def generate_rotational_assignments
    return empty_assignments if no_active_children?

    assignments = ChoreAssignments.new
    difficulty_tracker = DifficultyTracker.new
    
    hardest_chores_first.each do |chore|
      assign_chore_to_best_candidate(chore, assignments, difficulty_tracker)
    end

    assignments.to_hash
  end

  private

  def no_active_children?
    @active_children.empty?
  end

  def empty_assignments
    {}
  end

  def hardest_chores_first
    rotational_chores.sort_by(&:difficulty_weight).reverse
  end

  def rotational_chores
    @family.chores.active.rotational
  end

  def assign_chore_to_best_candidate(chore, assignments, difficulty_tracker)
    eligible_children = find_age_appropriate_children(chore)
    return if eligible_children.empty?

    selected_child = select_optimal_child(chore, eligible_children, difficulty_tracker)
    assignments.add_chore_to_child(selected_child, chore)
    difficulty_tracker.add_weight_for_child(selected_child, chore.difficulty_weight)
    record_assignment_in_database(chore, selected_child)
  end

  def find_age_appropriate_children(chore)
    @active_children.select { |child| chore.age_appropriate_for?(child) }
  end

  def select_optimal_child(chore, eligible_children, difficulty_tracker)
    return eligible_children.first if only_one_candidate?(eligible_children)

    least_burdened_children = find_least_burdened_children(eligible_children, difficulty_tracker)
    
    return least_burdened_children.first if only_one_candidate?(least_burdened_children)
    
    break_tie_using_historical_rotation(chore, least_burdened_children)
  end

  def only_one_candidate?(candidates)
    candidates.one?
  end

  def find_least_burdened_children(eligible_children, difficulty_tracker)
    minimum_burden = difficulty_tracker.minimum_weight_among(eligible_children)
    eligible_children.select { |child| difficulty_tracker.weight_for(child) == minimum_burden }
  end

  def break_tie_using_historical_rotation(chore, candidates)
    rotation_calculator = ChoreRotationCalculator.new(chore, candidates)
    rotation_calculator.next_child_for_assignment(@date)
  end

  def record_assignment_in_database(chore, child)
    ChoreRotation.create!(
      chore: chore,
      child: child,
      assigned_date: @date
    )
  end

  # Value objects for better encapsulation
  class ChoreAssignments
    def initialize
      @assignments = {}
    end

    def add_chore_to_child(child, chore)
      @assignments[child] ||= []
      @assignments[child] << chore
    end

    def to_hash
      @assignments
    end
  end

  class DifficultyTracker
    def initialize
      @weights = Hash.new(0)
    end

    def add_weight_for_child(child, weight)
      @weights[child] += weight
    end

    def weight_for(child)
      @weights[child]
    end

    def minimum_weight_among(children)
      children.map { |child| weight_for(child) }.min
    end
  end
end