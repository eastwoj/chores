class ExtraAssignment < ApplicationRecord
  belongs_to :extra
  belongs_to :child

  validates :extra_id, uniqueness: { scope: :child_id }

  scope :active, -> { where(active: true) }

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end
end
