class Family < ApplicationRecord
  has_many :adults, dependent: :destroy
  has_many :children, dependent: :destroy
  has_many :chores, dependent: :destroy
  has_many :extras, dependent: :destroy
  has_one :family_setting, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }

  after_create :create_default_family_setting

  def active_children
    children.where(active: true)
  end

  def inactive_children
    children.where(active: false)
  end

  private

  def create_default_family_setting
    create_family_setting!(
      payout_interval_days: 7,
      base_chore_value: 0.50,
      auto_approve_after_hours: 48
    )
  end
end