class DailyChoreList < ApplicationRecord
  belongs_to :child

  validates :date, presence: true, uniqueness: { scope: :child_id }

  scope :for_date, ->(date) { where(date: date) }

  # DailyChoreList doesn't directly have chore_completions
  # Those belong to ChoreList instead
  # This model appears to be for tracking daily list generation, not completions
end
