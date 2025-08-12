require "rails_helper"

RSpec.describe "Production Fix Verification", type: :model do
  let(:family) { create(:family) }
  let!(:child1) { create(:child, family: family, first_name: "Child 1") }
  let!(:child2) { create(:child, family: family, first_name: "Child 2") }
  
  # Create multiple rotational chores including the problematic "feed cat"
  let!(:feed_cat) { create(:chore, family: family, title: "Feed the Cat", chore_type: :rotational, difficulty: :easy) }
  let!(:take_trash) { create(:chore, family: family, title: "Take Out Trash", chore_type: :rotational, difficulty: :easy) }
  let!(:vacuum) { create(:chore, family: family, title: "Vacuum Living Room", chore_type: :rotational, difficulty: :medium) }
  let!(:clean_bath) { create(:chore, family: family, title: "Clean Bathroom", chore_type: :rotational, difficulty: :medium) }
  let!(:organize) { create(:chore, family: family, title: "Organize Garage", chore_type: :rotational, difficulty: :hard) }

  describe "production issue resolution" do
    it "ALWAYS assigns ALL rotational chores regardless of button press count" do
      all_rotational_chores = family.chores.active.rotational
      
      # Test multiple generation attempts (simulating button presses)
      5.times do |attempt|
        test_date = Date.current + attempt.days
        puts "\n--- Generation Attempt #{attempt + 1} (#{test_date}) ---"
        
        # Generate chores for a fresh date
        generator = DailyChoreListGenerator.new(family, test_date)
        generator.generate_for_all_children
        
        # Verify ALL rotational chores are assigned
        assigned_completions = ChoreCompletion.joins(:chore)
                                            .where(assigned_date: test_date)
                                            .where(chores: { family: family, chore_type: :rotational })
        
        assigned_chore_ids = assigned_completions.pluck(:chore_id).sort
        expected_chore_ids = all_rotational_chores.pluck(:id).sort
        
        puts "Expected chores: #{all_rotational_chores.pluck(:title).join(', ')}"
        puts "Assigned chores: #{assigned_completions.joins(:chore).pluck('chores.title').join(', ')}"
        
        # THE CRITICAL TEST: No chores should be missing
        missing_chores = all_rotational_chores.where.not(id: assigned_chore_ids)
        if missing_chores.any?
          puts "❌ MISSING: #{missing_chores.pluck(:title).join(', ')}"
        else
          puts "✅ All chores assigned successfully"
        end
        
        expect(missing_chores).to be_empty, 
               "Attempt #{attempt + 1}: These chores were NOT assigned: #{missing_chores.pluck(:title).join(', ')}"
        
        # Specifically verify "Feed the Cat" is always assigned
        feed_cat_assigned = assigned_completions.joins(:chore).exists?(chores: { title: "Feed the Cat" })
        expect(feed_cat_assigned).to be true
      end
    end
    
    it "maintains balanced difficulty distribution while ensuring complete assignment" do
      generator = DailyChoreListGenerator.new(family, Date.current)
      generator.generate_for_all_children
      
      # Get assignments for each child
      child1_completions = ChoreCompletion.joins(:chore)
                                        .where(child: child1, assigned_date: Date.current)
                                        .where(chores: { chore_type: :rotational })
      
      child2_completions = ChoreCompletion.joins(:chore)
                                        .where(child: child2, assigned_date: Date.current)
                                        .where(chores: { chore_type: :rotational })
      
      # Calculate difficulty weights
      child1_weight = child1_completions.joins(:chore).sum { |c| c.chore.difficulty_weight }
      child2_weight = child2_completions.joins(:chore).sum { |c| c.chore.difficulty_weight }
      
      puts "\nDifficulty Distribution:"
      puts "Child 1: #{child1_completions.joins(:chore).pluck('chores.title').join(', ')} (weight: #{child1_weight})"
      puts "Child 2: #{child2_completions.joins(:chore).pluck('chores.title').join(', ')} (weight: #{child2_weight})"
      
      # Both children must have chores
      expect(child1_completions.count).to be > 0, "Child 1 must have at least one chore"
      expect(child2_completions.count).to be > 0, "Child 2 must have at least one chore"
      
      # Difficulty should be balanced (within 1 point)
      expect((child1_weight - child2_weight).abs).to be <= 1,
             "Difficulty should be balanced within 1 point. Child1: #{child1_weight}, Child2: #{child2_weight}"
      
      # Total assignments should equal total chores
      total_assigned = child1_completions.count + child2_completions.count
      total_rotational = family.chores.active.rotational.count
      expect(total_assigned).to eq(total_rotational),
             "All #{total_rotational} rotational chores must be assigned, but only #{total_assigned} were assigned"
    end
    
    it "works correctly with pre-existing ChoreRotation history" do
      # Simulate existing rotation history (common in production)
      ChoreRotation.create!(
        chore: feed_cat,
        child: child1,
        assigned_date: 2.days.ago
      )
      
      ChoreRotation.create!(
        chore: take_trash,
        child: child2,
        assigned_date: 1.day.ago
      )
      
      generator = DailyChoreListGenerator.new(family, Date.current)
      generator.generate_for_all_children
      
      # Verify all chores are still assigned despite existing history
      all_rotational_chores = family.chores.active.rotational
      assigned_completions = ChoreCompletion.joins(:chore)
                                          .where(assigned_date: Date.current)
                                          .where(chores: { family: family, chore_type: :rotational })
      
      assigned_chore_ids = assigned_completions.pluck(:chore_id).sort
      expected_chore_ids = all_rotational_chores.pluck(:id).sort
      
      expect(assigned_chore_ids).to eq(expected_chore_ids),
             "All rotational chores should be assigned despite existing history"
             
      # Feed the cat should definitely be assigned
      feed_cat_assigned = assigned_completions.joins(:chore).exists?(chores: { title: "Feed the Cat" })
      expect(feed_cat_assigned).to be true
    end
  end
end