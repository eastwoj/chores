class Adult < ApplicationRecord
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :trackable

  belongs_to :family
  has_many :adult_roles, dependent: :destroy
  has_many :roles, through: :adult_roles

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def parent?
    has_role?("parent")
  end

  def guardian?
    has_role?("guardian")
  end

  def admin?
    has_role?("admin")
  end

  def can_review_chores?
    parent? || guardian? || admin?
  end

  def can_manage_family_settings?
    parent? || admin?
  end
end
