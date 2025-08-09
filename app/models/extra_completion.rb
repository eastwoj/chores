class ExtraCompletion < ApplicationRecord
  belongs_to :child
  belongs_to :extra
  belongs_to :approved_by, class_name: "Adult", optional: true

  validates :status, presence: true
  validates :earned_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :status, { 
    pending: 0, 
    completed: 1, 
    approved: 2, 
    rejected: 3 
  }

  scope :needing_approval, -> { completed.where(approved_at: nil) }
  scope :recent, -> { where("created_at > ?", 7.days.ago) }

  def mark_completed!
    update!(
      status: :completed,
      completed_at: Time.current,
      earned_amount: extra.reward_amount
    )
  end

  def approve!(approver, notes = nil)
    update!(
      status: :approved,
      approved_at: Time.current,
      approved_by: approver,
      notes: notes
    )
  end

  def reject!(approver, notes = nil)
    update!(
      status: :rejected,
      approved_at: Time.current,
      approved_by: approver,
      notes: notes,
      earned_amount: 0.0
    )
  end

  def needs_approval?
    completed? && approved_at.nil?
  end

  def overdue_for_approval?(hours = 48)
    return false unless completed?
    return false if approved_at.present?
    
    completed_at < hours.hours.ago
  end
end
