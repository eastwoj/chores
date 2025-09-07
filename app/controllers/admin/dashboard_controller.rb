class Admin::DashboardController < Admin::BaseController
  def index
    authorize :admin_dashboard, :index?
    
    @family = current_adult.family
    @children = @family.children.active
    
    # Ensure today's chore lists exist for all active children (only if they don't already exist)
    @family.ensure_daily_chore_lists_exist
    
    @today_chore_lists = ChoreList.joins(:child)
                                  .where(child: @children, start_date: Date.current, interval: :daily)
                                  .includes(:chore_completions, :child)
    
    # Pay period information
    @current_pay_period = @family.current_pay_period
    @payout_service = PayoutService.new(@family, current_adult)
    @payout_preview = @payout_service.payout_preview if @current_pay_period
    @detailed_earnings = @current_pay_period.detailed_earnings_by_child if @current_pay_period
    @period_ended = @current_pay_period&.end_date && @current_pay_period.end_date < Date.current
    
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

  def generate_chores
    authorize :admin_dashboard, :generate_chores?
    
    @family = current_adult.family
    date = Date.current
    extras_excluded = @family.family_setting&.exclude_extras_today || false
    
    # Explicitly regenerate daily chore lists for all active children
    # This clears existing chores and generates fresh ones (used by the manual "Generate Chores" button)
    @family.generate_daily_chore_lists
    
    # Create detailed success message
    date_str = date.strftime("%A, %B %d, %Y")
    extras_status = extras_excluded ? "with extras excluded" : "with extras available"
    
    redirect_to admin_root_path, notice: "Chores generated for #{date_str} #{extras_status}!"
  rescue StandardError => e
    Rails.logger.error "Error generating chores: #{e.message}"
    redirect_to admin_root_path, alert: "Failed to generate chores. Please try again."
  end

  def toggle_extras
    authorize :admin_dashboard, :generate_chores?
    
    @family = current_adult.family
    family_setting = @family.family_setting
    date_str = Date.current.strftime("%A, %B %d")
    
    # Toggle the exclude_extras_today setting
    new_value = !family_setting.exclude_extras_today
    family_setting.update!(exclude_extras_today: new_value)
    
    message = new_value ? "Extras excluded for #{date_str}." : "Extras are now available for #{date_str}."
    redirect_to admin_root_path, notice: message
  rescue StandardError => e
    Rails.logger.error "Error toggling extras: #{e.message}"
    redirect_to admin_root_path, alert: "Failed to update extras setting. Please try again."
  end
end