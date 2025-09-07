class Admin::PayPeriodsController < Admin::BaseController
  def index
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @pay_periods = @family.pay_periods
                          .includes(children: [:chore_completions, :extra_completions])
                          .order(created_at: :desc)
                          .limit(20)
    
    @detailed_earnings_by_period = {}
    @pay_periods.each do |period|
      @detailed_earnings_by_period[period.id] = period.detailed_earnings_by_child
    end
  end

  def show
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @pay_period = @family.pay_periods.find(params[:id])
    @detailed_earnings = @pay_period.detailed_earnings_by_child
  end
end