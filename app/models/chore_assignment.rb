class ChoreAssignment < ApplicationRecord
  belongs_to :chore
  belongs_to :child

  validates :chore_id, uniqueness: { scope: :child_id }

  scope :active, -> { where(active: true) }

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end
end
