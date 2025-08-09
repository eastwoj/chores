require "test_helper"

class StreakCalculatorTest < ActiveSupport::TestCase
  setup do
    @child = children(:alice)
    @calculator = StreakCalculator.new(@child)
  end

  test "initializes with child" do
    assert_equal @child, @calculator.instance_variable_get(:@child)
  end

  test "current_completion_streak returns 0 when no chore lists exist" do
    @child.daily_chore_lists.destroy_all
    
    assert_equal 0, @calculator.current_completion_streak
  end

  test "current_completion_streak calculates consecutive 100% completion days" do
    # Create 5 consecutive days of 100% completion
    5.times do |days_ago|
      list = @child.daily_chore_lists.create!(
        date: days_ago.days.ago.to_date
      )

      3.times do
        list.chore_completions.create!(
          chore: chores(:make_bed),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago
        )
      end
    end

    # Add a day with incomplete chores (should stop streak counting here)
    broken_list = @child.daily_chore_lists.create!(
      date: 6.days.ago.to_date
    )
    broken_list.chore_completions.create!(
      chore: chores(:make_bed),
      child: @child,
      status: :completed,
      completed_at: 6.days.ago
    )
    broken_list.chore_completions.create!(
      chore: chores(:clean_room),
      child: @child,
      status: :pending
    )

    assert_equal 5, @calculator.current_completion_streak
  end

  test "current_completion_streak stops at first incomplete day" do
    # Create today with 100% completion
    today_list = @child.daily_chore_lists.create!(
      date: Date.current
    )
    2.times do
      today_list.chore_completions.create!(
        chore: chores(:make_bed),
        child: @child,
        status: :completed,
        completed_at: Time.current
      )
    end

    # Create yesterday with incomplete chores
    yesterday_list = @child.daily_chore_lists.create!(
      date: 1.day.ago.to_date
    )
    yesterday_list.chore_completions.create!(
      chore: chores(:make_bed),
      child: @child,
      status: :completed,
      completed_at: 1.day.ago
    )
    yesterday_list.chore_completions.create!(
      chore: chores(:clean_room),
      child: @child,
      status: :pending
    )

    # Should only count today (streak broken by yesterday)
    assert_equal 1, @calculator.current_completion_streak
  end

  test "current_completion_streak returns 0 if today is incomplete" do
    # Create today with incomplete chores
    today_list = @child.daily_chore_lists.create!(
      date: Date.current
    )
    today_list.chore_completions.create!(
      chore: chores(:make_bed),
      child: @child,
      status: :completed,
      completed_at: Time.current
    )
    today_list.chore_completions.create!(
      chore: chores(:clean_room),
      child: @child,
      status: :pending
    )

    # Create previous days with 100% completion
    3.times do |days_ago|
      next if days_ago == 0 # Skip today
      
      list = @child.daily_chore_lists.create!(
        date: (days_ago + 1).days.ago.to_date
      )

      2.times do
        list.chore_completions.create!(
          chore: chores(:make_bed),
          child: @child,
          status: :completed,
          completed_at: (days_ago + 1).days.ago
        )
      end
    end

    assert_equal 0, @calculator.current_completion_streak
  end

  test "longest_completion_streak finds best historical streak" do
    # Create a pattern: 3 perfect days, 1 bad day, 5 perfect days, 1 bad day, 2 perfect days
    
    # Most recent 2 perfect days
    2.times do |days_ago|
      list = @child.daily_chore_lists.create!(
        date: days_ago.days.ago.to_date
      )

      3.times do
        list.chore_completions.create!(
          chore: chores(:make_bed),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago
        )
      end
    end

    # 1 bad day
    bad_list1 = @child.daily_chore_lists.create!(
      date: 3.days.ago.to_date
    )
    bad_list1.chore_completions.create!(
      chore: chores(:make_bed),
      child: @child,
      status: :completed,
      completed_at: 3.days.ago
    )
    bad_list1.chore_completions.create!(
      chore: chores(:clean_room),
      child: @child,
      status: :pending
    )

    # 5 perfect days (this should be the longest streak)
    5.times do |i|
      days_ago = i + 4
      list = @child.daily_chore_lists.create!(
        date: days_ago.days.ago.to_date
      )

      3.times do
        list.chore_completions.create!(
          chore: chores(:make_bed),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago
        )
      end
    end

    # 1 bad day
    bad_list2 = @child.daily_chore_lists.create!(
      date: 10.days.ago.to_date
    )
    bad_list2.chore_completions.create!(
      chore: chores(:make_bed),
      child: @child,
      status: :pending
    )

    # 3 perfect days
    3.times do |i|
      days_ago = i + 11
      list = @child.daily_chore_lists.create!(
        date: days_ago.days.ago.to_date
      )

      2.times do
        list.chore_completions.create!(
          chore: chores(:make_bed),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago
        )
      end
    end

    assert_equal 5, @calculator.longest_completion_streak
  end

  test "current_bonus calculates reward based on streak length" do
    # Mock streak lengths and test bonus calculation
    
    # Streak of 3 days
    calculator_with_3_streak = StreakCalculator.new(@child)
    calculator_with_3_streak.define_singleton_method(:current_completion_streak) { 3 }
    assert_equal 0.50, calculator_with_3_streak.current_bonus

    # Streak of 7 days
    calculator_with_7_streak = StreakCalculator.new(@child)
    calculator_with_7_streak.define_singleton_method(:current_completion_streak) { 7 }
    assert_equal 1.50, calculator_with_7_streak.current_bonus

    # Streak of 14 days
    calculator_with_14_streak = StreakCalculator.new(@child)
    calculator_with_14_streak.define_singleton_method(:current_completion_streak) { 14 }
    assert_equal 3.50, calculator_with_14_streak.current_bonus

    # Streak of 30 days
    calculator_with_30_streak = StreakCalculator.new(@child)
    calculator_with_30_streak.define_singleton_method(:current_completion_streak) { 30 }
    assert_equal 8.00, calculator_with_30_streak.current_bonus
  end

  test "current_bonus returns 0 for streaks less than 3" do
    # No streak
    calculator_with_0_streak = StreakCalculator.new(@child)
    calculator_with_0_streak.define_singleton_method(:current_completion_streak) { 0 }
    assert_equal 0.0, calculator_with_0_streak.current_bonus

    # Streak of 1 day
    calculator_with_1_streak = StreakCalculator.new(@child)
    calculator_with_1_streak.define_singleton_method(:current_completion_streak) { 1 }
    assert_equal 0.0, calculator_with_1_streak.current_bonus

    # Streak of 2 days
    calculator_with_2_streak = StreakCalculator.new(@child)
    calculator_with_2_streak.define_singleton_method(:current_completion_streak) { 2 }
    assert_equal 0.0, calculator_with_2_streak.current_bonus
  end

  test "days_until_next_bonus calculates days needed for next milestone" do
    # At 5 days, next milestone is 7 days (need 2 more)
    calculator_with_5_streak = StreakCalculator.new(@child)
    calculator_with_5_streak.define_singleton_method(:current_completion_streak) { 5 }
    assert_equal 2, calculator_with_5_streak.days_until_next_bonus

    # At 7 days, next milestone is 14 days (need 7 more)
    calculator_with_7_streak = StreakCalculator.new(@child)
    calculator_with_7_streak.define_singleton_method(:current_completion_streak) { 7 }
    assert_equal 7, calculator_with_7_streak.days_until_next_bonus

    # At 20 days, next milestone is 30 days (need 10 more)
    calculator_with_20_streak = StreakCalculator.new(@child)
    calculator_with_20_streak.define_singleton_method(:current_completion_streak) { 20 }
    assert_equal 10, calculator_with_20_streak.days_until_next_bonus
  end

  test "days_until_next_bonus returns nil when at maximum milestone" do
    # At 30+ days, no higher milestone exists
    calculator_with_30_streak = StreakCalculator.new(@child)
    calculator_with_30_streak.define_singleton_method(:current_completion_streak) { 30 }
    assert_nil calculator_with_30_streak.days_until_next_bonus

    calculator_with_50_streak = StreakCalculator.new(@child)
    calculator_with_50_streak.define_singleton_method(:current_completion_streak) { 50 }
    assert_nil calculator_with_50_streak.days_until_next_bonus
  end

  test "milestone_bonuses returns correct bonus structure" do
    expected_bonuses = {
      3 => 0.50,
      7 => 1.50,
      14 => 3.50,
      30 => 8.00
    }

    assert_equal expected_bonuses, @calculator.milestone_bonuses
  end

  test "streak_level categorizes streak length appropriately" do
    test_cases = [
      { streak: 0, level: "none" },
      { streak: 2, level: "none" },
      { streak: 3, level: "bronze" },
      { streak: 6, level: "bronze" },
      { streak: 7, level: "silver" },
      { streak: 13, level: "silver" },
      { streak: 14, level: "gold" },
      { streak: 29, level: "gold" },
      { streak: 30, level: "platinum" },
      { streak: 50, level: "platinum" }
    ]

    test_cases.each do |test_case|
      calculator = StreakCalculator.new(@child)
      calculator.define_singleton_method(:current_completion_streak) { test_case[:streak] }
      
      assert_equal test_case[:level], calculator.streak_level, 
        "Expected streak of #{test_case[:streak]} to be level '#{test_case[:level]}'"
    end
  end

  test "is_at_milestone? returns true for exact milestone days" do
    [3, 7, 14, 30].each do |milestone|
      calculator = StreakCalculator.new(@child)
      calculator.define_singleton_method(:current_completion_streak) { milestone }
      
      assert calculator.is_at_milestone?, 
        "Expected streak of #{milestone} days to be at milestone"
    end
  end

  test "is_at_milestone? returns false for non-milestone days" do
    [0, 1, 2, 4, 5, 6, 8, 10, 15, 25, 31].each do |non_milestone|
      calculator = StreakCalculator.new(@child)
      calculator.define_singleton_method(:current_completion_streak) { non_milestone }
      
      refute calculator.is_at_milestone?, 
        "Expected streak of #{non_milestone} days to NOT be at milestone"
    end
  end
end