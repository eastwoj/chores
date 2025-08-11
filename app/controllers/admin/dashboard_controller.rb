class Admin::DashboardController < Admin::BaseController
  def index
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @children = @family.children.active
    
    # Ensure today's chore lists exist for all active children (idempotent)
    @family.generate_daily_chore_lists
    
    @today_chore_lists = ChoreList.joins(:child)
                                  .where(child: @children, start_date: Date.current, interval: :daily)
                                  .includes(:chore_completions, :child)
    
    # Pay period information
    @current_pay_period = @family.current_pay_period
    @payout_service = PayoutService.new(@family, current_adult)
    @payout_preview = @payout_service.payout_preview if @current_pay_period
    
    # Notifications
    @unread_notifications = @family.payout_notifications
                                   .where(adult: current_adult)
                                   .unread
                                   .recent
                                   .limit(5)
    
    # Send payout reminder if needed
    if @payout_service.next_payout_reminder_needed?
      @payout_service.send_payout_reminder!
      @unread_notifications = @unread_notifications.reload
    end
    
    # Get pending review counts for the dashboard button
    @pending_chore_completions = ChoreCompletion.joins(:child)
                                                .where(child: @family.children)
                                                .where(assigned_date: Date.current)
                                                .where(completed_at: ..Time.current)
                                                .where(reviewed_at: nil)
    
    @pending_extra_completions = ExtraCompletion.joins(:child)
                                               .where(child: @family.children)
                                               .where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
                                               .where(status: [:completed])
  end
end