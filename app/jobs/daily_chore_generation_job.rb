class DailyChoreGenerationJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    Family.all.find_each do |family|
      begin
        family.generate_daily_chore_lists(date)
        Rails.logger.info "Daily chore lists generated for family #{family.name} on #{date}"
      rescue => e
        Rails.logger.error "Failed to generate chore lists for family #{family.id}: #{e.message}"
        # Could add Sentry or other error reporting here
        raise e if Rails.env.development?
      end
    end
  end
end