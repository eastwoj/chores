namespace :chores do
  desc "Generate sample historical chore data for testing"
  task generate_sample_history: :environment do
    puts "Generating sample historical chore data..."
    
    families = Family.includes(:children, :chores).limit(1)
    
    families.each do |family|
      puts "Processing family: #{family.name}"
      
      children = family.children.active
      chores = family.chores.active
      
      if children.empty? || chores.empty?
        puts "  Skipping - no children or chores found"
        next
      end
      
      # Generate chore data for the past 30 days
      (30.days.ago.to_date..Date.current).each do |date|
        puts "  Generating data for #{date}"
        
        children.each do |child|
          # Random number of chores per day (1-4)
          num_chores = rand(1..4)
          selected_chores = chores.sample(num_chores)
          
          chore_list = child.chore_lists.find_or_create_by!(
            start_date: date,
            interval: :daily
          )
          
          selected_chores.each do |chore|
            next if chore_list.chore_completions.exists?(chore: chore, assigned_date: date)
            
            # Random completion status
            status = [:pending, :completed, :reviewed_satisfactory, :reviewed_unsatisfactory].sample
            
            completion = chore_list.chore_completions.create!(
              chore: chore,
              child: child,
              assigned_date: date,
              status: status
            )
            
            # Set realistic timestamps based on status
            case status
            when :completed
              completion.update!(completed_at: date.to_time + rand(8..20).hours)
            when :reviewed_satisfactory, :reviewed_unsatisfactory
              completed_time = date.to_time + rand(8..16).hours
              reviewed_time = completed_time + rand(1..8).hours
              reviewer = family.adults.first
              
              completion.update!(
                completed_at: completed_time,
                reviewed_at: reviewed_time,
                reviewed_by: reviewer
              )
            end
          end
        end
      end
    end
    
    puts "Sample historical data generation complete!"
  end
end