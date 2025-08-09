class ChildRole < ApplicationRecord
  belongs_to :child
  belongs_to :role

  validates :child_id, uniqueness: { scope: :role_id }
end
