require "test_helper"

class SimpleCompletionPercentageTest < ActiveSupport::TestCase
  test "calculator initializes correctly" do
    family = create(:family)
    child = create(:child, family: family)
    chore_list = create(:chore_list, child: child)
    calculator = CompletionPercentageCalculator.new(chore_list)
    
    assert_not_nil calculator
    assert_equal chore_list, calculator.instance_variable_get(:@daily_chore_list)
  end

  test "returns 0 when no chores exist" do
    family = create(:family)
    child = create(:child, family: family)
    chore_list = create(:chore_list, child: child)
    calculator = CompletionPercentageCalculator.new(chore_list)
    
    assert_equal 0, calculator.calculate
  end

  test "returns 100 when all chores completed" do
    family = create(:family)
    child = create(:child, family: family)
    chore = create(:chore, family: family)
    chore_list = create(:chore_list, child: child)
    
    # Create completed chore completion
    create(:chore_completion, :completed,
           chore_list: chore_list,
           chore: chore,
           child: child,
           assigned_date: Date.current)
    
    calculator = CompletionPercentageCalculator.new(chore_list)
    assert_equal 100, calculator.calculate
  end
end