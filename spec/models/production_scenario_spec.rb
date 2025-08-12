require "rails_helper"

RSpec.describe "Production Scenario - Missing Rotational Chores", type: :model do
  let(:family) { create(:family) }
  let!(:alice) { create(:child, family: family, first_name: "Alice", birth_date: 10.years.ago) }
  let!(:bob) { create(:child, family: family, first_name: "Bob", birth_date: 8.years.ago) }
  
  # Exact production scenario
  let!(:feed_cat) { create(:chore, family: family, title: "Feed the Cat", chore_type: :rotational, difficulty: :easy) }
  let!(:other_chore) { create(:chore, family: family, title: "Take Out Trash", chore_type: :rotational, difficulty: :easy) }
  
  let(:generator) { DailyChoreListGenerator.new(family, Date.current) }
  
  describe "production bug simulation with pre-existing data" do
    before do
      # Simulate some historical rotation data that might interfere
      ChoreRotation.create!(
        chore: feed_cat,
        child: alice,
        assigned_date: 5.days.ago
      )
      
      ChoreRotation.create!(
        chore: other_chore,
        child: bob,
        assigned_date: 3.days.ago
      )
    end
    
    it "assigns all rotational chores despite existing rotation history" do
      # Multiple runs to test consistency
      3.times do |run|
        date = Date.current + run.days
        test_generator = DailyChoreListGenerator.new(family, date)
        
        # Clear previous day's assignments
        ChoreCompletion.where(assigned_date: date).delete_all
        
        test_generator.generate_for_all_children
        
        all_rotational_chores = family.chores.active.rotational
        assigned_completions = ChoreCompletion.joins(:chore)
                                            .where(assigned_date: date)
                                            .where(chores: { family: family, chore_type: :rotational })
        
        assigned_chore_ids = assigned_completions.pluck(:chore_id).sort
        expected_chore_ids = all_rotational_chores.pluck(:id).sort
        
        expect(assigned_chore_ids).to eq(expected_chore_ids), 
               "Run #{run + 1}: Expected all rotational chores to be assigned on #{date}"
        
        # Specifically check feed_cat
        feed_cat_assigned = assigned_completions.joins(:chore).exists?(chores: { title: "Feed the Cat" })
        expect(feed_cat_assigned).to be true
      end
    end
  end
  
  describe "potential race conditions and edge cases" do
    it "handles concurrent generation attempts safely" do
      # Simulate what might happen if generate is called multiple times
      generator.generate_for_all_children
      initial_count = ChoreCompletion.where(assigned_date: Date.current).count
      
      # Call again (should be idempotent)
      generator.generate_for_all_children
      final_count = ChoreCompletion.where(assigned_date: Date.current).count
      
      expect(final_count).to eq(initial_count), "Generation should be idempotent"
      
      # Still all chores should be assigned
      all_rotational_chores = family.chores.active.rotational
      assigned_completions = ChoreCompletion.joins(:chore)
                                          .where(assigned_date: Date.current)
                                          .where(chores: { family: family, chore_type: :rotational })
      
      expect(assigned_completions.count).to eq(all_rotational_chores.count),
             "All rotational chores should still be assigned after multiple calls"
    end
    
    it "handles chores with identical difficulty and no rotation history" do
      # Create several chores with same difficulty (common production scenario)
      chore1 = create(:chore, family: family, title: "Chore A", chore_type: :rotational, difficulty: :easy)
      chore2 = create(:chore, family: family, title: "Chore B", chore_type: :rotational, difficulty: :easy) 
      chore3 = create(:chore, family: family, title: "Chore C", chore_type: :rotational, difficulty: :easy)
      
      generator.generate_for_all_children
      
      [chore1, chore2, chore3, feed_cat, other_chore].each do |chore|
        assigned = ChoreCompletion.joins(:chore)
                                 .where(assigned_date: Date.current, chore: chore)
                                 .exists?
        
        expect(assigned).to be true
      end
    end
  end
  
  describe "debugging rotational assignment step by step" do
    it "traces the assignment process for troubleshooting" do
      # Let's trace exactly what happens during assignment
      rotation_generator = ChoreRotationGenerator.new(family, Date.current)
      
      puts "\n=== DEBUGGING ROTATIONAL ASSIGNMENT ==="
      puts "Family: #{family.name}"
      puts "Children: #{[alice.name, bob.name].join(', ')}"
      
      all_rotational_chores = family.chores.active.rotational
      puts "Rotational chores: #{all_rotational_chores.pluck(:title).join(', ')}"
      
      assignments = rotation_generator.generate_rotational_assignments
      
      puts "Assignment results:"
      assignments.each do |child, chores|
        puts "  #{child.name}: #{chores.map(&:title).join(', ')}"
      end
      
      # Verify all chores were assigned
      all_assigned_chores = assignments.values.flatten
      missing_chores = all_rotational_chores - all_assigned_chores
      
      if missing_chores.any?
        puts "❌ MISSING CHORES: #{missing_chores.map(&:title).join(', ')}"
      else
        puts "✅ All rotational chores assigned successfully"
      end
      
      expect(missing_chores).to be_empty, 
             "These chores were not assigned: #{missing_chores.map(&:title).join(', ')}"
    end
  end
end