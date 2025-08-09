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

    rotational_chores.each do |chore|
      eligible_children = find_eligible_children(chore)
      next if eligible_children.empty?

      assigned_child = select_child_for_rotation(chore, eligible_children)
      assignments[assigned_child] ||= []
      assignments[assigned_child] << chore

      record_rotation(chore, assigned_child)
    end

    assignments
  end

  private

  def find_eligible_children(chore)
    @children.select { |child| chore.age_appropriate_for?(child) }
  end

  def select_child_for_rotation(chore, eligible_children)
    rotation_calculator = ChoreRotationCalculator.new(chore, eligible_children)
    rotation_calculator.next_child_for_assignment(@date)
  end

  def record_rotation(chore, child)
    ChoreRotation.create!(
      chore: chore,
      child: child,
      assigned_date: @date
    )
  end
end