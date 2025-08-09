class ChoreList < ApplicationRecord
  belongs_to :child
  has_many :chore_completions, dependent: :destroy
  has_many :chores, through: :chore_completions

  validates :interval, presence: true
  validates :start_date, presence: true
  validates :start_date, uniqueness: { scope: [:child_id, :interval] }

  enum :interval, { daily: 0, weekly: 1, monthly: 2 }

  scope :for_date, ->(date) { where(start_date: date) }
  scope :current, -> { where(start_date: Date.current) }

  def completion_percentage
    return 0 if chore_completions.empty?
    
    PercentageCalculator.new(completed_count, total_count).calculate
  end

  def completed_count
    chore_completions.completed.count
  end

  def total_count
    chore_completions.count
  end

  def pending_review_count
    chore_completions.completed.where(status: [:completed]).count - 
    chore_completions.reviewed_satisfactory.count
  end

  def all_completed?
    chore_completions.all?(&:completed?)
  end

  def needs_review?
    pending_review_count > 0
  end

  def end_date
    IntervalCalculator.new(start_date, interval).calculate_end_date
  end

  def active_period?
    Date.current.between?(start_date, end_date)
  end

  private

  class PercentageCalculator
    def initialize(completed, total)
      @completed = completed
      @total = total
    end

    def calculate
      return 0 if @total.zero?
      
      ((@completed.to_f / @total) * 100).round
    end
  end

  class IntervalCalculator
    def initialize(start_date, interval)
      @start_date = start_date
      @interval = interval
    end

    def calculate_end_date
      case @interval.to_s
      when "daily"
        @start_date
      when "weekly"
        @start_date + 6.days
      when "monthly"
        @start_date.end_of_month
      else
        @start_date
      end
    end
  end
end
