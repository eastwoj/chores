class AdultRole < ApplicationRecord
  belongs_to :adult
  belongs_to :role

  validates :adult_id, uniqueness: { scope: :role_id }
end
