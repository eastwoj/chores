require "test_helper"

class SimpleEarningsTest < ActiveSupport::TestCase
  test "earnings calculator initializes correctly" do
    family = create(:family)
    child = create(:child, family: family)
    calculator = EarningsCalculator.new(child)
    
    assert_not_nil calculator
    assert_equal child, calculator.instance_variable_get(:@child)
  end

  test "current_period_total returns 0 when no completions" do
    family = create(:family)
    child = create(:child, family: family)
    calculator = EarningsCalculator.new(child)
    
    assert_equal 0.0, calculator.current_period_total
  end
end