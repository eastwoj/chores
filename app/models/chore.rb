class Chore < ApplicationRecord
  belongs_to :family
  has_many :chore_assignments, dependent: :destroy
  has_many :assigned_children, through: :chore_assignments, source: :child
  has_many :chore_completions, dependent: :destroy
  has_many :chore_rotations, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :chore_type, presence: true
  validates :difficulty, presence: true
  validates :base_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :estimated_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validates :min_age, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_age, numericality: { greater_than: 0 }, allow_nil: true

  enum :chore_type, { constant: 0, rotational: 1 }
  enum :difficulty, { easy: 0, medium: 1, hard: 2 }

  def name
    title
  end


  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :age_appropriate_for, ->(age) { 
    where("(min_age IS NULL OR min_age <= ?) AND (max_age IS NULL OR max_age >= ?)", age, age) 
  }

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  def age_appropriate_for?(child)
    return true unless child.age
    return true if min_age.nil? && max_age.nil?
    return false if min_age && child.age < min_age
    return false if max_age && child.age > max_age
    
    true
  end

  def estimated_duration
    return "Unknown" unless estimated_minutes?
    
    DurationFormatter.new(estimated_minutes).format
  end

  private

  class DurationFormatter
    def initialize(minutes)
      @minutes = minutes
    end

    def format
      return "#{@minutes} min" if @minutes < 60
      
      hours = @minutes / 60
      remaining_minutes = @minutes % 60
      
      return "#{hours} hr" if remaining_minutes.zero?
      
      "#{hours} hr #{remaining_minutes} min"
    end
  end
end
