require "test_helper"

class CompletionPercentageCalculatorTest < ActiveSupport::TestCase
  setup do
    @family = create(:family)
    @child = create(:child, family: @family)
    @chore_list = create(:chore_list, child: @child)
    @calculator = CompletionPercentageCalculator.new(@chore_list)
  end

  test "initializes with chore list" do
    assert_equal @chore_list, @calculator.instance_variable_get(:@daily_chore_list)
  end

  test "calculate returns 0 when no chores exist" do
    @chore_list.chore_completions.destroy_all
    
    assert_equal 0, @calculator.calculate
  end

  test "calculate returns 0 when no chores are completed" do
    # Create pending chore completions
    3.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :pending,
        assigned_date: Date.current
      )
    end

    assert_equal 0, @calculator.calculate
  end

  test "calculate returns 100 when all chores are completed" do
    # Create completed chore completions
    3.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :completed,
        completed_at: Time.current,
        assigned_date: Date.current
      )
    end

    assert_equal 100, @calculator.calculate
  end

  test "calculate returns correct percentage for partial completion" do
    # Create mix of completed and pending chores
    2.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :completed,
        completed_at: Time.current,
        assigned_date: Date.current
      )
    end

    3.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :pending,
        assigned_date: Date.current
      )
    end

    # 2 completed out of 5 total = 40%
    assert_equal 40, @calculator.calculate
  end

  test "calculate counts reviewed_satisfactory as completed" do
    # Create reviewed satisfactory completions
    2.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :reviewed_satisfactory,
        completed_at: 1.day.ago,
        reviewed_at: Time.current,
        assigned_date: Date.current
      )
    end

    # Create pending completion
    create(:chore_completion,
      chore_list: @chore_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :pending,
      assigned_date: Date.current
    )

    # 2 completed out of 3 total = 67% (rounded)
    assert_equal 67, @calculator.calculate
  end

  test "calculate does not count reviewed_unsatisfactory as completed" do
    # Create unsatisfactory completion
    create(:chore_completion,
      chore_list: @chore_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :reviewed_unsatisfactory,
      completed_at: 1.day.ago,
      reviewed_at: Time.current,
      assigned_date: Date.current
    )

    # Create completed completion
    create(:chore_completion,
      chore_list: @chore_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :completed,
      completed_at: Time.current,
      assigned_date: Date.current
    )

    # 1 completed out of 2 total = 50%
    assert_equal 50, @calculator.calculate
  end

  test "calculate rounds to nearest integer" do
    # Create scenario that results in 66.66...%
    2.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :completed,
        completed_at: Time.current,
        assigned_date: Date.current
      )
    end

    create(:chore_completion,
      chore_list: @chore_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :pending,
      assigned_date: Date.current
    )

    # 2 completed out of 3 total = 66.666...% -> 67%
    assert_equal 67, @calculator.calculate
  end

  test "calculate handles large numbers correctly" do
    # Create 100 chores, 33 completed
    33.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :completed,
        completed_at: Time.current,
        assigned_date: Date.current
      )
    end

    67.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :pending,
        assigned_date: Date.current
      )
    end

    assert_equal 33, @calculator.calculate
  end

  test "completed_chores counts all completed statuses" do
    # Create various completion statuses
    create(:chore_completion,
      chore_list: @chore_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :completed,
      completed_at: Time.current,
      assigned_date: Date.current
    )

    create(:chore_completion,
      chore_list: @chore_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :reviewed_satisfactory,
      completed_at: 1.day.ago,
      reviewed_at: Time.current,
      assigned_date: Date.current
    )

    create(:chore_completion,
      chore_list: @chore_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :reviewed_unsatisfactory,
      completed_at: 1.day.ago,
      reviewed_at: Time.current,
      assigned_date: Date.current
    )

    create(:chore_completion,
      chore_list: @chore_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :pending,
      assigned_date: Date.current
    )

    # Should count completed and reviewed_satisfactory (2 out of 4)
    assert_equal 2, @calculator.send(:completed_chores)
  end

  test "total_chores counts all chore completions" do
    5.times do |i|
      create(:chore_completion,
        chore_list: @chore_list,
        chore: create(:chore, family: @family),
        child: @child,
        status: :pending,
        assigned_date: Date.current
      )
    end

    assert_equal 5, @calculator.send(:total_chores)
  end

  test "works with different chore lists" do
    other_child = create(:child, family: @family)
    other_list = create(:chore_list, child: other_child)
    other_calculator = CompletionPercentageCalculator.new(other_list)

    # Add chores to other list
    2.times do |i|
      create(:chore_completion,
        chore_list: other_list,
        chore: create(:chore, family: @family),
        child: other_child,
        status: :completed,
        completed_at: Time.current,
        assigned_date: Date.current
      )
    end

    create(:chore_completion,
      chore_list: other_list,
      chore: create(:chore, family: @family),
      child: other_child,
      status: :pending,
      assigned_date: Date.current
    )

    # Should not affect original calculator
    assert_equal 0, @calculator.calculate # No chores in alice_today list
    assert_equal 67, other_calculator.calculate # 2/3 = 67%
  end
end