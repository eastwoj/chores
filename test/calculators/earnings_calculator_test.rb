require "test_helper"

class EarningsCalculatorTest < ActiveSupport::TestCase
  setup do
    @family = create(:family)
    @child = create(:child, family: @family)
    @family_setting = @family.family_setting
    @calculator = EarningsCalculator.new(@child)
  end

  test "initializes with child and family setting" do
    assert_equal @child, @calculator.instance_variable_get(:@child)
    assert_equal @family_setting, @calculator.instance_variable_get(:@family_setting)
  end

  test "current_period_total returns sum of chore and extra earnings for current period" do
    daily_list = create(:daily_chore_list, child: @child)
    
    # Create reviewed satisfactory chore completion in current period
    create(:chore_completion, :reviewed_satisfactory,
           child: @child,
           daily_chore_list: daily_list,
           earned_amount: 1.50,
           reviewed_at: 2.days.ago
    )

    # Create approved extra completion in current period
    create(:extra_completion, :approved,
           child: @child,
           earned_amount: 5.00,
           approved_at: 1.day.ago
    )

    # Create old completion outside current period (should not be included)
    old_list = create(:daily_chore_list, child: @child, date: 32.days.ago)
    create(:chore_completion, :reviewed_satisfactory,
           child: @child,
           daily_chore_list: old_list,
           earned_amount: 0.75,
           reviewed_at: 32.days.ago
    )

    assert_equal 6.50, @calculator.current_period_total
  end

  test "lifetime_total returns sum of all historical earnings" do
    # Create multiple completions across time periods
    chore_completion1 = chore_completions(:alice_make_bed_today)
    chore_completion1.update!(
      status: :reviewed_satisfactory,
      earned_amount: 1.50
    )

    chore_completion2 = chore_completions(:alice_make_bed_last_month)
    chore_completion2.update!(
      status: :reviewed_satisfactory,
      earned_amount: 0.75
    )

    extra_completion = extra_completions(:alice_wash_car)
    extra_completion.update!(
      status: :approved,
      earned_amount: 5.00
    )

    # Unsatisfactory completion should not count
    bad_completion = chore_completions(:alice_clean_room_bad)
    bad_completion.update!(
      status: :reviewed_unsatisfactory,
      earned_amount: 1.00
    )

    assert_equal 7.25, @calculator.lifetime_total
  end

  test "projected_weekly_earnings returns 0 when insufficient history" do
    # Clear any existing completions
    @child.chore_completions.destroy_all

    assert_equal 0.0, @calculator.projected_weekly_earnings
  end

  test "projected_weekly_earnings calculates weekly average from 4 weeks of data" do
    # Create completions over 4 weeks with total of $20
    4.times do |week|
      completion = @child.chore_completions.create!(
        chore: chores(:make_bed),
        daily_chore_list: daily_chore_lists(:alice_today),
        status: :reviewed_satisfactory,
        earned_amount: 5.00,
        created_at: (week + 1).weeks.ago,
        reviewed_at: (week + 1).weeks.ago
      )
    end

    assert_equal 5.0, @calculator.projected_weekly_earnings
  end

  test "projected_weekly_earnings returns 0 when no recent completions" do
    # Create old completions outside 4-week window
    2.times do |i|
      @child.chore_completions.create!(
        chore: chores(:make_bed),
        daily_chore_list: daily_chore_lists(:alice_today),
        status: :reviewed_satisfactory,
        earned_amount: 2.00,
        created_at: (5 + i).weeks.ago,
        reviewed_at: (5 + i).weeks.ago
      )
    end

    assert_equal 0.0, @calculator.projected_weekly_earnings
  end

  test "calculate_for_chore applies difficulty multipliers correctly" do
    easy_chore = chores(:make_bed)
    easy_chore.update!(difficulty: :easy, base_value: 1.00)

    medium_chore = chores(:clean_room)
    medium_chore.update!(difficulty: :medium, base_value: 1.00)

    hard_chore = chores(:organize_garage)
    hard_chore.update!(difficulty: :hard, base_value: 1.00)

    assert_equal 1.00, @calculator.calculate_for_chore(easy_chore)
    assert_equal 1.50, @calculator.calculate_for_chore(medium_chore)
    assert_equal 2.00, @calculator.calculate_for_chore(hard_chore)
  end

  test "calculate_for_chore uses family setting base value when chore has no base value" do
    chore = chores(:make_bed)
    chore.update!(base_value: nil, difficulty: :easy)
    @family_setting.update!(base_chore_value: 0.75)

    assert_equal 0.75, @calculator.calculate_for_chore(chore)
  end

  test "calculate_for_chore handles unknown difficulty gracefully" do
    chore = chores(:make_bed)
    chore.update!(base_value: 1.00)
    # Simulate invalid difficulty
    chore.define_singleton_method(:difficulty) { "unknown" }

    assert_equal 1.00, @calculator.calculate_for_chore(chore)
  end

  test "current_period_start calculates weekly periods correctly" do
    @family_setting.update!(payout_interval_days: 7)
    calculator = EarningsCalculator.new(@child)

    travel_to Date.parse("2025-01-15") do # Wednesday
      expected_start = Date.parse("2025-01-13") # Monday of same week
      assert_equal expected_start, calculator.send(:current_period_start)
    end
  end

  test "current_period_start calculates bi-weekly periods correctly" do
    @family_setting.update!(payout_interval_days: 14)
    calculator = EarningsCalculator.new(@child)

    # Test even week
    travel_to Date.parse("2025-01-15") do # Week 3 (odd)
      expected_start = Date.parse("2025-01-06") # Monday of week 2 (even)
      assert_equal expected_start, calculator.send(:current_period_start)
    end
  end

  test "current_period_start calculates monthly periods correctly" do
    @family_setting.update!(payout_interval_days: 30)
    calculator = EarningsCalculator.new(@child)

    travel_to Date.parse("2025-01-15") do
      expected_start = Date.parse("2025-01-01")
      assert_equal expected_start, calculator.send(:current_period_start)
    end
  end

  test "current_period_start handles custom intervals" do
    @family_setting.update!(payout_interval_days: 10)
    calculator = EarningsCalculator.new(@child)

    travel_to Date.parse("2025-01-15") do
      expected_start = Date.parse("2025-01-05") # 10 days ago
      assert_equal expected_start, calculator.send(:current_period_start)
    end
  end

  test "sufficient_history? returns true when child has enough completions" do
    @child.chore_completions.destroy_all
    
    # Create 5 completions in last 4 weeks
    5.times do |i|
      @child.chore_completions.create!(
        chore: chores(:make_bed),
        daily_chore_list: daily_chore_lists(:alice_today),
        created_at: i.days.ago
      )
    end

    assert @calculator.send(:sufficient_history?)
  end

  test "sufficient_history? returns false when child has insufficient completions" do
    @child.chore_completions.destroy_all
    
    # Create only 4 completions
    4.times do |i|
      @child.chore_completions.create!(
        chore: chores(:make_bed),
        daily_chore_list: daily_chore_lists(:alice_today),
        created_at: i.days.ago
      )
    end

    refute @calculator.send(:sufficient_history?)
  end

  test "sufficient_history? returns false when completions are too old" do
    @child.chore_completions.destroy_all
    
    # Create 6 completions but all older than 4 weeks
    6.times do |i|
      @child.chore_completions.create!(
        chore: chores(:make_bed),
        daily_chore_list: daily_chore_lists(:alice_today),
        created_at: (5.weeks + i.days).ago
      )
    end

    refute @calculator.send(:sufficient_history?)
  end
end