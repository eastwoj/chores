class Admin::PayoutsController < Admin::BaseController
  before_action :set_current_period, only: [:show, :create]

  def show
    @payout_service = PayoutService.new(current_family, current_adult)
    @payout_preview = @payout_service.payout_preview
    
    unless @payout_preview[:success]
      redirect_to admin_dashboard_path, alert: @payout_preview[:error]
      return
    end

    @earnings_by_child = @payout_preview[:earnings_by_child]
    @total_payout = @payout_preview[:total_payout]
    @can_payout = @payout_preview[:can_payout]
    @blocked_reason = @payout_preview[:blocked_reason]
    @period_dates = @payout_preview[:period_dates]
  end

  def create
    payout_service = PayoutService.new(current_family, current_adult)
    result = payout_service.process_payout!

    if result[:success]
      redirect_to admin_dashboard_path, 
                  notice: "Payout completed successfully! #{format_payout_summary(result[:data])}"
    else
      redirect_to admin_payout_path, alert: result[:error]
    end
  end

  private

  def set_current_period
    @current_period = current_family.current_pay_period
    unless @current_period
      redirect_to admin_dashboard_path, alert: "No current pay period found"
    end
  end

  def format_payout_summary(earnings_summary)
    total = earnings_summary.values.sum { |child| child[:total_earnings] }
    child_count = earnings_summary.keys.count
    "Total: $#{total.round(2)} across #{child_count} #{'child'.pluralize(child_count)}"
  end
end