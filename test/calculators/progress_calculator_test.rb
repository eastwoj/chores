require "test_helper"

class ProgressCalculatorTest < ActiveSupport::TestCase
  setup do
    @family = create(:family)
    @child = create(:child, family: @family)
    @calculator = ProgressCalculator.new(@child)
  end

  test "initializes with child" do
    assert_equal @child, @calculator.instance_variable_get(:@child)
  end

  test "weekly_completion_rate returns 0 when no chore lists exist" do
    @child.chore_lists.destroy_all
    
    assert_equal 0.0, @calculator.weekly_completion_rate
  end

  test "weekly_completion_rate calculates average completion over week" do
    # Create daily chore lists for the past week
    7.times do |days_ago|
      list = create(:chore_list, child: @child, interval: :daily, start_date: days_ago.days.ago.to_date)

      # Add chores with varying completion rates
      if days_ago < 3
        # Recent 3 days: 100% completion
        2.times do
          create(:chore_completion,
            chore_list: list,
            chore: create(:chore, family: @family),
            child: @child,
            status: :completed,
            completed_at: days_ago.days.ago,
            assigned_date: days_ago.days.ago.to_date
          )
        end
      else
        # Older 4 days: 50% completion
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago,
          assigned_date: days_ago.days.ago.to_date
        )
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :pending,
          assigned_date: days_ago.days.ago.to_date
        )
      end
    end

    # Expected: (100 + 100 + 100 + 50 + 50 + 50 + 50) / 7 = 71.43%
    expected_rate = 71.43
    assert_in_delta expected_rate, @calculator.weekly_completion_rate, 0.01
  end

  test "monthly_completion_rate calculates average over 30 days" do
    # Create lists for different periods
    30.times do |days_ago|
      list = create(:chore_list, child: @child, interval: :daily, start_date: days_ago.days.ago.to_date)

      # First 10 days: 90% completion
      # Next 10 days: 60% completion  
      # Last 10 days: 30% completion
      completion_rate = case days_ago
                       when 0...10
                         0.9
                       when 10...20
                         0.6
                       else
                         0.3
                       end

      total_chores = 10
      completed_chores = (total_chores * completion_rate).to_i

      completed_chores.times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago,
          assigned_date: days_ago.days.ago.to_date
        )
      end

      (total_chores - completed_chores).times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :pending,
          assigned_date: days_ago.days.ago.to_date
        )
      end
    end

    # Expected: (90*10 + 60*10 + 30*10) / 30 = 1800/30 = 60%
    assert_equal 60.0, @calculator.monthly_completion_rate
  end

  test "completion_trend returns improving when recent performance is better" do
    create_performance_data(recent_rate: 80, historical_rate: 60)
    
    assert_equal "improving", @calculator.completion_trend
  end

  test "completion_trend returns declining when recent performance is worse" do
    create_performance_data(recent_rate: 40, historical_rate: 70)
    
    assert_equal "declining", @calculator.completion_trend
  end

  test "completion_trend returns stable when performance is similar" do
    create_performance_data(recent_rate: 65, historical_rate: 67)
    
    assert_equal "stable", @calculator.completion_trend
  end

  test "completion_streak calculates consecutive days of 100% completion" do
    # Create a streak of 5 consecutive days with 100% completion
    5.times do |days_ago|
      list = create(:chore_list, child: @child, interval: :daily, start_date: days_ago.days.ago.to_date)

      3.times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago,
          assigned_date: days_ago.days.ago.to_date
        )
      end
    end

    # Add a day with incomplete chores to break any longer streak
    broken_list = create(:chore_list, child: @child, interval: :daily, start_date: 6.days.ago.to_date)
    create(:chore_completion,
      chore_list: broken_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :completed,
      completed_at: 6.days.ago,
      assigned_date: 6.days.ago.to_date
    )
    create(:chore_completion,
      chore_list: broken_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :pending,
      assigned_date: 6.days.ago.to_date
    )

    assert_equal 5, @calculator.completion_streak
  end

  test "completion_streak returns 0 when today is not 100%" do
    # Create today's list with incomplete chores
    today_list = create(:chore_list, child: @child, interval: :daily, start_date: Date.current)
    create(:chore_completion,
      chore_list: today_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :completed,
      completed_at: Time.current,
      assigned_date: Date.current
    )
    create(:chore_completion,
      chore_list: today_list,
      chore: create(:chore, family: @family),
      child: @child,
      status: :pending,
      assigned_date: Date.current
    )

    assert_equal 0, @calculator.completion_streak
  end

  test "best_day_percentage returns highest single day completion" do
    # Create lists with different completion rates
    [100, 75, 90, 60, 95].each_with_index do |percentage, days_ago|
      list = create(:chore_list, child: @child, interval: :daily, start_date: days_ago.days.ago.to_date)

      total_chores = 20
      completed_chores = (total_chores * percentage / 100.0).to_i

      completed_chores.times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago,
          assigned_date: days_ago.days.ago.to_date
        )
      end

      (total_chores - completed_chores).times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :pending,
          assigned_date: days_ago.days.ago.to_date
        )
      end
    end

    assert_equal 100, @calculator.best_day_percentage
  end

  test "best_day_percentage returns 0 when no chore lists exist" do
    @child.chore_lists.destroy_all
    
    assert_equal 0, @calculator.best_day_percentage
  end

  test "average_chores_per_day calculates daily chore load" do
    # Create 7 days of lists with varying chore counts
    chore_counts = [5, 3, 7, 4, 6, 2, 8]
    
    chore_counts.each_with_index do |count, days_ago|
      list = create(:chore_list, child: @child, interval: :daily, start_date: days_ago.days.ago.to_date)

      count.times do |i|
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :pending,
          assigned_date: days_ago.days.ago.to_date
        )
      end
    end

    expected_average = chore_counts.sum.to_f / chore_counts.length
    assert_equal expected_average, @calculator.average_chores_per_day(7)
  end

  test "average_chores_per_day handles custom day ranges" do
    # Create 14 days with 5 chores each
    14.times do |days_ago|
      list = create(:chore_list, child: @child, interval: :daily, start_date: days_ago.days.ago.to_date)

      5.times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :pending,
          assigned_date: days_ago.days.ago.to_date
        )
      end
    end

    assert_equal 5.0, @calculator.average_chores_per_day(7) # Last 7 days
    assert_equal 5.0, @calculator.average_chores_per_day(14) # Last 14 days
    assert_equal 5.0, @calculator.average_chores_per_day(30) # Should handle missing days
  end

  private

  def create_performance_data(recent_rate:, historical_rate:)
    # Create recent data (last 7 days)
    7.times do |days_ago|
      list = create(:chore_list, child: @child, interval: :daily, start_date: days_ago.days.ago.to_date)

      total_chores = 10
      completed_chores = (total_chores * recent_rate / 100.0).to_i

      completed_chores.times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago,
          assigned_date: days_ago.days.ago.to_date
        )
      end

      (total_chores - completed_chores).times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :pending,
          assigned_date: days_ago.days.ago.to_date
        )
      end
    end

    # Create historical data (8-14 days ago)
    (8..14).each do |days_ago|
      list = create(:chore_list, child: @child, interval: :daily, start_date: days_ago.days.ago.to_date)

      total_chores = 10
      completed_chores = (total_chores * historical_rate / 100.0).to_i

      completed_chores.times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :completed,
          completed_at: days_ago.days.ago,
          assigned_date: days_ago.days.ago.to_date
        )
      end

      (total_chores - completed_chores).times do
        create(:chore_completion,
          chore_list: list,
          chore: create(:chore, family: @family),
          child: @child,
          status: :pending,
          assigned_date: days_ago.days.ago.to_date
        )
      end
    end
  end
end