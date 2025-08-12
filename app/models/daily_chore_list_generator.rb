class DailyChoreListGenerator
  def initialize(family, date = Date.current)
    @family = family
    @date = date
  end

  def generate_for_all_children
    # Clear existing assignments for today before regenerating
    clear_existing_assignments_for_date
    
    @family.children.active.each do |child|
      generate_for_child(child)
    end
  end

  def generate_for_child(child)
    constant_chores = collect_constant_chores(child)
    rotational_chores = collect_rotational_chores(child)
    
    create_daily_list(child)
    create_chore_completions(child, constant_chores + rotational_chores)
  end

  private

  def clear_existing_assignments_for_date
    # Clear existing chore completions for this date and family
    ChoreCompletion.joins(:child)
                   .where(assigned_date: @date, children: { family: @family })
                   .destroy_all
    
    # Clear existing chore lists for this date and family
    ChoreList.joins(:child)
             .where(start_date: @date, interval: :daily, children: { family: @family })
             .destroy_all
    
    # Clear existing daily chore lists for this date and family
    DailyChoreList.joins(:child)
                  .where(date: @date, children: { family: @family })
                  .destroy_all
    
    # Clear existing chore rotations for this date and family
    ChoreRotation.joins(chore: :family)
                 .where(assigned_date: @date, chores: { family: @family })
                 .destroy_all
  end

  def collect_constant_chores(child)
    child.constant_chores.active.select { |chore| chore.age_appropriate_for?(child) }
  end

  def collect_rotational_chores(child)
    rotation_assignments = rotational_assignments_for_date
    rotation_assignments[child] || []
  end

  def rotational_assignments_for_date
    @rotational_assignments ||= ChoreRotationGenerator.new(@family, @date)
                                                       .generate_rotational_assignments
  end

  def create_daily_list(child)
    child.daily_chore_lists.create!(
      date: @date,
      generated_at: Time.current
    )
  end

  def create_chore_completions(child, chores)
    chore_list = find_or_create_chore_list(child)
    
    chores.each do |chore|
      chore_list.chore_completions.create!(
        chore: chore,
        child: child,
        assigned_date: @date,
        status: :pending
      )
    end
  end

  def find_or_create_chore_list(child)
    child.chore_lists.find_or_create_by!(
      start_date: @date,
      interval: :daily
    )
  end
end