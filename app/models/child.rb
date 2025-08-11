class Child < ApplicationRecord
  belongs_to :family
  has_many :child_roles, dependent: :destroy
  has_many :roles, through: :child_roles
  has_many :chore_lists, dependent: :destroy
  has_many :daily_chore_lists, dependent: :destroy
  has_many :chore_completions, dependent: :destroy
  has_many :extra_completions, dependent: :destroy
  has_many :chore_assignments, dependent: :destroy
  has_many :constant_chores, -> { where(chore_type: :constant) }, 
    through: :chore_assignments, 
    source: :chore
  has_many :chore_rotations, dependent: :destroy
  has_many :extra_assignments, dependent: :destroy
  has_many :assigned_extras, through: :extra_assignments, source: :extra

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :birth_date, presence: true
  validates :avatar_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def name
    first_name
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def age
    return nil unless birth_date?
    
    AgeCalculator.new(birth_date).calculate_in_years
  end

  def total_earnings
    current_period_earnings
  end

  def current_period_earnings
    current_period = family.current_pay_period
    return 0 unless current_period

    extra_completions
      .approved
      .where(approved_at: current_period.start_date.beginning_of_day..current_period.end_date.end_of_day)
      .sum(:earned_amount)
  end

  def all_time_earnings
    extra_completions.approved.sum(:earned_amount)
  end

  # Keep for backward compatibility
  def lifetime_earnings
    all_time_earnings
  end


  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  def age_appropriate_chores
    return family.chores.none unless age

    family.chores.active.where(
      "(min_age IS NULL OR min_age <= ?) AND (max_age IS NULL OR max_age >= ?)", 
      age, age
    )
  end

  private

  class AgeCalculator
    def initialize(birth_date)
      @birth_date = birth_date
    end

    def calculate_in_years
      ((Date.current - @birth_date) / 365.25).floor
    end
  end
end
