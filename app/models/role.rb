class Role < ApplicationRecord
  has_many :child_roles, dependent: :destroy
  has_many :children, through: :child_roles
  has_many :adult_roles, dependent: :destroy
  has_many :adults, through: :adult_roles

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }
end
