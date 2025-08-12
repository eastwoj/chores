require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @family = create(:complete_family)
    @admin_role = create(:role, name: "admin")
    @adult = create(:adult, family: @family)
    create(:adult_role, adult: @adult, role: @admin_role)
    @children = @family.children.active
    
    # Create constant chores that should be assigned to ALL children
    @constant_easy = create(:chore, family: @family, title: "Make Bed", chore_type: :constant, difficulty: :easy)
    @constant_medium = create(:chore, family: @family, title: "Brush Teeth", chore_type: :constant, difficulty: :medium)
    
    # Create rotational chores that should be distributed equally by difficulty
    @rotation_easy_1 = create(:chore, family: @family, title: "Take Out Trash", chore_type: :rotational, difficulty: :easy)
    @rotation_easy_2 = create(:chore, family: @family, title: "Feed Pets", chore_type: :rotational, difficulty: :easy)
    @rotation_medium_1 = create(:chore, family: @family, title: "Vacuum Living Room", chore_type: :rotational, difficulty: :medium)
    @rotation_medium_2 = create(:chore, family: @family, title: "Clean Bathroom", chore_type: :rotational, difficulty: :medium)
    @rotation_hard_1 = create(:chore, family: @family, title: "Organize Garage", chore_type: :rotational, difficulty: :hard)
    @rotation_hard_2 = create(:chore, family: @family, title: "Wash Car", chore_type: :rotational, difficulty: :hard)
    
    sign_in @adult
  end

  test "should get index" do
    get admin_root_path
    assert_response :success
  end

  test "should generate today's chores when button clicked" do
    assert_difference -> { ChoreCompletion.where(assigned_date: Date.current).count } do
      post generate_chores_admin_dashboard_index_path
    end
    
    assert_redirected_to admin_root_path
    assert_equal "Today's chores have been generated successfully!", flash[:notice]
  end

  test "should assign ALL constant chores to ALL children" do
    post generate_chores_admin_dashboard_index_path
    
    @children.each do |child|
      # Each child should have both constant chores assigned
      constant_completions = ChoreCompletion.joins(:chore)
                                          .where(child: child, assigned_date: Date.current)
                                          .where(chores: { chore_type: :constant })
      
      assert_equal 2, constant_completions.count, "Child #{child.name} should have 2 constant chores"
      
      # Check specific constant chores are assigned
      assert constant_completions.joins(:chore).exists?(chores: { id: @constant_easy.id })
      assert constant_completions.joins(:chore).exists?(chores: { id: @constant_medium.id })
    end
  end

  test "should assign ALL rotational chores with equal difficulty distribution" do
    post generate_chores_admin_dashboard_index_path
    
    # Get all rotational chore completions for today
    rotational_completions = ChoreCompletion.joins(:chore)
                                          .where(assigned_date: Date.current)
                                          .where(chores: { chore_type: :rotational })
    
    # All rotational chores should be assigned (none missed)
    assigned_chore_ids = rotational_completions.pluck(:chore_id)
    expected_rotational_ids = [@rotation_easy_1.id, @rotation_easy_2.id, 
                              @rotation_medium_1.id, @rotation_medium_2.id,
                              @rotation_hard_1.id, @rotation_hard_2.id]
    
    assert_equal expected_rotational_ids.sort, assigned_chore_ids.sort, "All rotational chores should be assigned"
    
    # Check difficulty distribution is equal across children
    difficulty_weights_by_child = {}
    @children.each do |child|
      child_rotational = rotational_completions.where(child: child)
      total_weight = child_rotational.joins(:chore).sum("CASE 
        WHEN chores.difficulty = 0 THEN 1 
        WHEN chores.difficulty = 1 THEN 2 
        WHEN chores.difficulty = 2 THEN 3 
        ELSE 1 END")
      difficulty_weights_by_child[child.id] = total_weight
    end
    
    # All children should have similar difficulty weights (within 1 point of each other)
    min_weight = difficulty_weights_by_child.values.min
    max_weight = difficulty_weights_by_child.values.max
    
    assert max_weight - min_weight <= 1, 
           "Difficulty distribution should be balanced. Weights: #{difficulty_weights_by_child}"
  end

  test "should not duplicate chores if already generated for today" do
    # Generate chores once
    post generate_chores_admin_dashboard_index_path
    initial_count = ChoreCompletion.where(assigned_date: Date.current).count
    
    # Try to generate again - should be idempotent
    post generate_chores_admin_dashboard_index_path
    final_count = ChoreCompletion.where(assigned_date: Date.current).count
    
    assert_equal initial_count, final_count, "Should not create duplicate chores for same day"
    assert_equal "Today's chores have been generated successfully!", flash[:notice]
  end

  test "should only assign age-appropriate chores" do
    # Create age-restricted chore for teenagers only
    teen_chore = create(:chore, family: @family, title: "Drive to Store", 
                       chore_type: :constant, min_age: 16)
    
    post generate_chores_admin_dashboard_index_path
    
    # No children under 16 should have this chore
    @children.each do |child|
      next if child.age >= 16
      
      completions = ChoreCompletion.where(child: child, chore: teen_chore, assigned_date: Date.current)
      assert_equal 0, completions.count, "Child #{child.name} (age #{child.age}) should not have age-restricted chore"
    end
  end

  test "should require authentication" do
    sign_out @adult
    
    post generate_chores_admin_dashboard_index_path
    assert_redirected_to new_adult_session_path
  end
end