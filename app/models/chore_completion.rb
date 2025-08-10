class ChoreCompletion < ApplicationRecord
  belongs_to :chore_list
  belongs_to :chore
  belongs_to :child
  belongs_to :reviewed_by, class_name: "Adult", optional: true

  validates :status, presence: true
  validates :earned_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :assigned_date, presence: true

  before_validation :set_default_values, on: :create

  enum :status, { 
    pending: 0, 
    completed: 1, 
    reviewed_satisfactory: 2, 
    reviewed_unsatisfactory: 3 
  }

  scope :needing_review, -> { completed.where(reviewed_at: nil) }
  scope :recent, -> { where("created_at > ?", 7.days.ago) }

  def mark_completed!
    update!(
      status: :completed,
      completed_at: Time.current
    )
  end

  def mark_uncompleted!
    update!(
      status: :pending,
      completed_at: nil
    )
  end

  def mark_reviewed_satisfactory!(reviewer)
    update!(
      status: :reviewed_satisfactory,
      reviewed_at: Time.current,
      reviewed_by: reviewer
    )
  end

  def mark_reviewed_unsatisfactory!(reviewer, notes = nil)
    update!(
      status: :reviewed_unsatisfactory,
      reviewed_at: Time.current,
      reviewed_by: reviewer,
      review_notes: notes
    )
  end

  def needs_review?
    completed? && reviewed_at.nil?
  end

  def overdue_for_review?(hours = 48)
    return false unless completed?
    return false if reviewed_at.present?
    
    completed_at < hours.hours.ago
  end


  private

  def set_default_values
    # Regular chores don't earn money, only points
    self.earned_amount ||= 0
  end
end
