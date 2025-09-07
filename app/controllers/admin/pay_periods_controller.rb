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

  def complete
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @pay_period = @family.pay_periods.find(params[:id])
    
    unless @pay_period.current_period?
      redirect_to admin_root_path, alert: "Can only complete the current pay period"
      return
    end

    begin
      @pay_period.force_complete!
      redirect_to admin_root_path, 
                  notice: "Pay period marked complete. New period has been started."
    rescue StandardError => e
      Rails.logger.error "Error completing pay period: #{e.message}"
      redirect_to admin_root_path, alert: "Failed to complete pay period. Please try again."
    end
  end
end