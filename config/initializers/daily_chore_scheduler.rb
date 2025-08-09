# Simple daily chore list generation scheduler
# This will be enhanced with a proper scheduling system later
# For now, this provides the foundation for daily generation

Rails.application.configure do
  # In production, you would use whenever gem or similar to schedule this job
  # For development, jobs can be triggered manually or via admin interface
  
  if Rails.env.production?
    # Schedule the daily job to run at midnight
    # This would typically be done with whenever gem or systemd timer
    # DailyChoreGenerationJob.set(cron: "0 0 * * *").perform_later
  end
end