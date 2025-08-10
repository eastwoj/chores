class PayoutNotification < ApplicationRecord
  belongs_to :family
  belongs_to :pay_period
  belongs_to :adult

  validates :title, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def self.create_payout_reminder(pay_period)
    earnings = pay_period.earnings_by_child
    total_amount = pay_period.total_earnings_for_period
    child_count = earnings.count
    
    return if total_amount <= 0

    title = "Payout Reminder: $#{sprintf('%.2f', total_amount)} Due"
    
    message_parts = [
      "It's time to pay your children for the current #{pay_period.frequency_description.downcase} pay period",
      "(#{pay_period.start_date.strftime('%b %d')} - #{pay_period.end_date.strftime('%b %d')}).",
      "",
      "Earnings breakdown:"
    ]
    
    earnings.each do |child_id, earning_data|
      child_name = earning_data[:child].name
      amount = earning_data[:total]
      message_parts << "• #{child_name}: $#{sprintf('%.2f', amount)}"
    end
    
    message_parts << ""
    message_parts << "Total to pay: $#{sprintf('%.2f', total_amount)}"
    
    if pay_period.can_payout?
      message_parts << ""
      message_parts << "✅ Ready to process payout"
    else
      message_parts << ""
      message_parts << "⚠️ Payout blocked: #{pay_period.payout_blocked_reason}"
    end

    # Create notification for all adults in the family
    pay_period.family.adults.each do |adult|
      create!(
        family: pay_period.family,
        pay_period: pay_period,
        adult: adult,
        title: title,
        message: message_parts.join("\n")
      )
    end
  end
end
