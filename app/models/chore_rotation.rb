class ChoreRotation < ApplicationRecord
  belongs_to :chore
  belongs_to :child

  validates :assigned_date, presence: true
  validates :chore_id, uniqueness: { scope: [:child_id, :assigned_date] }

  scope :for_date, ->(date) { where(assigned_date: date) }
  scope :for_chore, ->(chore) { where(chore: chore) }
  scope :for_child, ->(child) { where(child: child) }
  scope :recent, ->(days = 30) { where(assigned_date: days.days.ago..Date.current) }
end