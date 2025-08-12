require "test_helper"

class DailyChoreListTest < ActiveSupport::TestCase
  def setup
    @family = create(:family)
    @child1 = create(:child, family: @family, first_name: "Alice")
    @child2 = create(:child, family: @family, first_name: "Bob")
    @child3 = create(:child, family: @family, first_name: "Charlie")
    
    # Create constant chores
    @constant_easy = create(:chore, family: @family, chore_type: :constant, difficulty: :easy)
    @constant_medium = create(:chore, family: @family, chore_type: :constant, difficulty: :medium)
    
    # Create rotational chores with various difficulties
    @rotation_easy_1 = create(:chore, family: @family, chore_type: :rotational, difficulty: :easy)
    @rotation_easy_2 = create(:chore, family: @family, chore_type: :rotational, difficulty: :easy)
    @rotation_medium_1 = create(:chore, family: @family, chore_type: :rotational, difficulty: :medium)
    @rotation_hard_1 = create(:chore, family: @family, chore_type: :rotational, difficulty: :hard)
    
    # Create chore assignments for constant chores
    create(:chore_assignment, child: @child1, chore: @constant_easy)
    create(:chore_assignment, child: @child2, chore: @constant_easy)
    create(:chore_assignment, child: @child3, chore: @constant_easy)
    create(:chore_assignment, child: @child1, chore: @constant_medium)
    create(:chore_assignment, child: @child2, chore: @constant_medium)
    create(:chore_assignment, child: @child3, chore: @constant_medium)
    
    @generator = DailyChoreListGenerator.new(@family, Date.current)
  end

  test "generates daily chore lists for all active children" do
    assert_difference -> { DailyChoreList.count }, 3 do
      @generator.generate_for_all_children
    end
    
    [@child1, @child2, @child3].each do |child|
      assert child.daily_chore_lists.exists?(date: Date.current)
    end
  end

  test "assigns all constant chores to all children" do
    @generator.generate_for_all_children
    
    [@child1, @child2, @child3].each do |child|
      constant_completions = ChoreCompletion.joins(:chore)
                                          .where(child: child, assigned_date: Date.current)
                                          .where(chores: { chore_type: :constant })
      
      assert_equal 2, constant_completions.count, "Child #{child.first_name} should have 2 constant chores"
    end
  end

  test "assigns all rotational chores with balanced difficulty distribution" do
    @generator.generate_for_all_children
    
    # All rotational chores should be assigned
    total_rotational_completions = ChoreCompletion.joins(:chore)
                                                .where(assigned_date: Date.current)
                                                .where(chores: { chore_type: :rotational })
    
    assigned_chore_ids = total_rotational_completions.pluck(:chore_id).sort
    expected_ids = [@rotation_easy_1.id, @rotation_easy_2.id, @rotation_medium_1.id, @rotation_hard_1.id].sort
    
    assert_equal expected_ids, assigned_chore_ids, "All rotational chores should be assigned"
    
    # Check difficulty weights are balanced
    difficulty_weights = {}
    [@child1, @child2, @child3].each do |child|
      child_rotational = total_rotational_completions.where(child: child)
      weight = child_rotational.joins(:chore).sum { |completion| completion.chore.difficulty_weight }
      difficulty_weights[child.id] = weight
    end
    
    # All children should have similar difficulty weights
    min_weight = difficulty_weights.values.min
    max_weight = difficulty_weights.values.max
    
    assert max_weight - min_weight <= 1, 
           "Rotational chore difficulty should be balanced. Weights: #{difficulty_weights}"
  end

  test "is idempotent - does not create duplicates" do
    @generator.generate_for_all_children
    initial_count = ChoreCompletion.where(assigned_date: Date.current).count
    
    # Run again
    @generator.generate_for_all_children
    final_count = ChoreCompletion.where(assigned_date: Date.current).count
    
    assert_equal initial_count, final_count, "Generator should be idempotent"
  end

  test "respects age restrictions" do
    # Create age-restricted chore
    teen_chore = create(:chore, family: @family, chore_type: :constant, min_age: 16)
    create(:chore_assignment, child: @child1, chore: teen_chore) # child1 is 10 years old
    
    @generator.generate_for_all_children
    
    # Child1 should not have the teen chore assigned
    completions = ChoreCompletion.where(child: @child1, chore: teen_chore, assigned_date: Date.current)
    assert_equal 0, completions.count, "Age-inappropriate chore should not be assigned"
  end
end
