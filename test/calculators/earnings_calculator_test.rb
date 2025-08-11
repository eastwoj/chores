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

  test "current_period_total returns sum of extra earnings for current period" do
    # Create approved extra completion in current period
    create(:extra_completion, :approved,
           child: @child,
           earned_amount: 5.00,
           approved_at: Date.current.beginning_of_week + 1.day
    )

    # Create old completion outside current period (should not be included)
    create(:extra_completion, :approved,
           child: @child,
           earned_amount: 2.50,
           approved_at: 32.days.ago
    )

    assert_equal 5.00, @calculator.current_period_total
  end

  test "lifetime_total returns sum of all approved extra earnings" do
    # Create multiple extra completions across time periods
    create(:extra_completion, :approved,
           child: @child,
           earned_amount: 5.00,
           approved_at: 1.day.ago
    )

    create(:extra_completion, :approved,
           child: @child,
           earned_amount: 3.00,
           approved_at: 1.month.ago
    )

    # Rejected completion should not count
    create(:extra_completion, :rejected,
           child: @child,
           earned_amount: 2.00
    )

    assert_equal 8.00, @calculator.lifetime_total
  end

  test "projected_weekly_earnings returns 0 when insufficient history" do
    # Clear any existing completions
    @child.extra_completions.destroy_all

    assert_equal 0.0, @calculator.projected_weekly_earnings
  end

  test "projected_weekly_earnings calculates weekly average from 4 weeks of data" do
    # Clear any existing completions first
    @child.extra_completions.destroy_all
    
    # Create exactly 5 approved completions (minimum for sufficient_history) over 3 weeks
    # Week 1: 2 completions
    2.times do |i|
      create(:extra_completion, :approved,
             child: @child,
             earned_amount: 4.00,
             created_at: 1.week.ago + i.days,
             approved_at: 1.week.ago + i.days
      )
    end
    
    # Week 2: 2 completions  
    2.times do |i|
      create(:extra_completion, :approved,
             child: @child,
             earned_amount: 4.00,
             created_at: 2.weeks.ago + i.days,
             approved_at: 2.weeks.ago + i.days
      )
    end
    
    # Week 3: 1 completion
    create(:extra_completion, :approved,
           child: @child,
           earned_amount: 4.00,
           created_at: 3.weeks.ago,
           approved_at: 3.weeks.ago
    )
    
    # Total: 5 * 4.00 = $20, weekly average = $20 / 4 weeks = $5.00
    assert_equal 5.00, @calculator.projected_weekly_earnings
  end

  test "projected_weekly_earnings returns 0 when no recent completions" do
    # Create old completions outside 4-week window
    2.times do |i|
      create(:extra_completion, :approved,
             child: @child,
             earned_amount: 2.00,
             created_at: (5 + i).weeks.ago,
             approved_at: (5 + i).weeks.ago
      )
    end

    assert_equal 0.0, @calculator.projected_weekly_earnings
  end

  # Note: These tests are now obsolete since chores don't have monetary value
  # Only extras have earnings in our business model

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
    @child.extra_completions.destroy_all
    
    # Create 5 completions in last 4 weeks
    5.times do |i|
      create(:extra_completion,
             child: @child,
             created_at: i.days.ago
      )
    end

    assert @calculator.send(:sufficient_history?)
  end

  test "sufficient_history? returns false when child has insufficient completions" do
    @child.extra_completions.destroy_all
    
    # Create only 4 completions
    4.times do |i|
      create(:extra_completion,
             child: @child,
             created_at: i.days.ago
      )
    end

    refute @calculator.send(:sufficient_history?)
  end

  test "sufficient_history? returns false when completions are too old" do
    @child.extra_completions.destroy_all
    
    # Create 6 completions but all older than 4 weeks
    6.times do |i|
      create(:extra_completion,
             child: @child,
             created_at: (5.weeks + i.days).ago
      )
    end

    refute @calculator.send(:sufficient_history?)
  end
end