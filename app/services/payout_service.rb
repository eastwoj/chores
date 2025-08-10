class PayoutService
  def initialize(family, adult)
    @family = family
    @adult = adult
    @current_period = family.current_pay_period
  end

  def process_payout!
    return failure("No current pay period found") unless @current_period
    return failure(@current_period.payout_blocked_reason) unless @current_period.can_payout?
    return failure("No earnings to pay out") unless @current_period.has_completions_to_pay?

    ActiveRecord::Base.transaction do
      @current_period.mark_as_completed!
      create_payout_notification
      success(earnings_summary)
    end
  rescue StandardError => e
    failure("Payout failed: #{e.message}")
  end

  def payout_preview
    return failure("No current pay period found") unless @current_period

    {
      success: true,
      earnings_by_child: @current_period.earnings_by_child,
      total_payout: @current_period.total_earnings_for_period,
      can_payout: @current_period.can_payout?,
      blocked_reason: @current_period.payout_blocked_reason,
      period_dates: {
        start_date: @current_period.start_date,
        end_date: @current_period.end_date
      }
    }
  end

  def next_payout_reminder_needed?
    return false unless @current_period&.payout_due?
    
    last_notification = @family.payout_notifications
                              .where(pay_period: @current_period)
                              .order(:created_at)
                              .last

    return true unless last_notification
    
    # Send reminder every 24 hours after first notification
    last_notification.created_at < 24.hours.ago
  end

  def send_payout_reminder!
    return unless @current_period&.payout_due?
    
    PayoutNotification.create_payout_reminder(@current_period)
  end

  private

  def success(data)
    { success: true, data: data }
  end

  def failure(message)
    { success: false, error: message }
  end

  def earnings_summary
    @current_period.earnings_by_child.transform_values do |child_data|
      {
        child_name: child_data[:child].name,
        total_earnings: child_data[:total],
        chore_earnings: child_data[:chore_earnings],
        extra_earnings: child_data[:extra_earnings]
      }
    end
  end

  def create_payout_notification
    # Mark existing payout reminder notifications as read
    @family.payout_notifications
           .where(pay_period: @current_period)
           .unread
           .each(&:mark_as_read!)

    Rails.logger.info "Payout completed for family #{@family.id} by adult #{@adult.id}"
  end
end