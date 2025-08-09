class Adult < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  belongs_to :family

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :role, presence: true

  enum :role, { parent: 0, guardian: 1, admin: 2 }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def can_review_chores?
    parent? || guardian? || admin?
  end

  def can_manage_family_settings?
    parent? || admin?
  end
end
