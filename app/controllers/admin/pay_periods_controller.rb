class Admin::PayPeriodsController < Admin::BaseController
  def index
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @pay_periods = @family.pay_periods
                          .order(created_at: :desc)
                          .limit(20)
    
    @detailed_earnings_by_period = {}
    @pay_periods.each do |period|
      begin
        @detailed_earnings_by_period[period.id] = period.detailed_earnings_by_child
      rescue => e
        Rails.logger.error "Error calculating earnings for period #{period.id}: #{e.message}"
        @detailed_earnings_by_period[period.id] = {}
      end
    end
  end

  def show
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @pay_period = @family.pay_periods.find(params[:id])
    @detailed_earnings = @pay_period.detailed_earnings_by_child
  end
end