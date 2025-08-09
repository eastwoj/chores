class Extra < ApplicationRecord
  belongs_to :family
  has_many :extra_completions, dependent: :destroy
  has_many :children, through: :extra_completions

  validates :title, presence: true, length: { maximum: 100 }
  validates :reward_amount, presence: true, numericality: { greater_than: 0 }
  validates :available_from, presence: true
  validates :available_until, presence: true
  validates :max_completions, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :available_on, ->(date) { 
    where("available_from <= ? AND available_until >= ?", date, date) 
  }
  scope :current, -> { available_on(Date.current) }

  def available_on?(date)
    date.between?(available_from, available_until)
  end

  def available_today?
    available_on?(Date.current)
  end

  def completion_slots_remaining
    return Float::INFINITY if max_completions.nil?
    
    used_slots = extra_completions.approved.count
    [max_completions - used_slots, 0].max
  end

  def can_be_completed_by?(child)
    return false unless active?
    return false unless available_today?
    return false if completion_slots_remaining.zero?
    
    true
  end

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end
end
