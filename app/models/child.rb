class Child < ApplicationRecord
  belongs_to :family
  has_many :chore_lists, dependent: :destroy
  has_many :chore_completions, dependent: :destroy
  has_many :extra_completions, dependent: :destroy
  has_many :chore_assignments, dependent: :destroy
  has_many :constant_chores, -> { where(chore_type: :constant) }, 
           through: :chore_assignments, 
           source: :chore

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :birth_date, presence: true
  validates :avatar_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def age
    return nil unless birth_date?
    
    AgeCalculator.new(birth_date).calculate_in_years
  end

  def current_period_earnings(payout_calculator = PayoutCalculator.new)
    payout_calculator.current_period_earnings_for(self)
  end

  def lifetime_earnings(payout_calculator = PayoutCalculator.new)
    payout_calculator.lifetime_earnings_for(self)
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
