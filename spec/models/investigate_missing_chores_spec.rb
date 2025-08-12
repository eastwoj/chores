require "rails_helper"

RSpec.describe "Investigate Missing Chores", type: :model do
  let(:family) { create(:family) }
  let!(:alice) { create(:child, family: family, first_name: "Alice", birth_date: 10.years.ago) }
  let!(:bob) { create(:child, family: family, first_name: "Bob", birth_date: 8.years.ago) }
  
  let!(:feed_cat) { create(:chore, family: family, title: "Feed the Cat", chore_type: :rotational, difficulty: :easy, active: true) }
  let!(:take_trash) { create(:chore, family: family, title: "Take Out Trash", chore_type: :rotational, difficulty: :easy, active: true) }
  
  describe "step by step investigation" do
    it "verifies the chore generation flow end-to-end" do
      puts "\n=== INVESTIGATING MISSING CHORES ==="
      
      # Step 1: Check initial state
      puts "1. Initial state:"
      puts "   - Family: #{family.name} (ID: #{family.id})"
      puts "   - Children: #{family.children.active.map { |c| "#{c.name} (#{c.age}y)" }.join(', ')}"
      puts "   - Rotational chores: #{family.chores.active.rotational.map(&:title).join(', ')}"
      
      # Step 2: Check for existing assignments (potential interference)
      existing = ChoreCompletion.where(assigned_date: Date.current, child: family.children)
      puts "2. Existing assignments for today: #{existing.count}"
      
      # Step 3: Run the generation
      puts "3. Running chore generation..."
      generator = DailyChoreListGenerator.new(family, Date.current)
      generator.generate_for_all_children
      
      # Step 4: Check what was created
      completions = ChoreCompletion.includes(:chore, :child)
                                   .where(assigned_date: Date.current, child: family.children)
      
      puts "4. Results after generation:"
      completions.each do |completion|
        puts "   - #{completion.child.name}: #{completion.chore.title} (#{completion.chore.chore_type})"
      end
      
      # Step 5: Specific check for our problematic chores
      feed_cat_assigned = completions.any? { |c| c.chore.title == "Feed the Cat" }
      take_trash_assigned = completions.any? { |c| c.chore.title == "Take Out Trash" }
      
      puts "5. Specific chore checks:"
      puts "   - Feed the Cat assigned: #{feed_cat_assigned}"
      puts "   - Take Out Trash assigned: #{take_trash_assigned}"
      
      # Step 6: Check the rotation generator directly
      puts "6. Direct rotation generator test:"
      rotation_gen = ChoreRotationGenerator.new(family, Date.current)
      assignments = rotation_gen.generate_rotational_assignments
      
      all_assigned_chores = assignments.values.flatten.map(&:title)
      puts "   - Direct assignment result: #{all_assigned_chores.join(', ')}"
      
      # Step 7: Final verification
      all_rotational_chores = family.chores.active.rotational
      missing_from_completions = all_rotational_chores.reject do |chore|
        completions.any? { |c| c.chore_id == chore.id }
      end
      
      if missing_from_completions.any?
        puts "❌ PROBLEM FOUND: Missing chores from ChoreCompletions: #{missing_from_completions.map(&:title).join(', ')}"
      else
        puts "✅ All rotational chores found in ChoreCompletions"
      end
      
      # This test should fail if chores are missing, helping us identify the exact issue
      expect(missing_from_completions).to be_empty
      expect(feed_cat_assigned).to be true
      expect(take_trash_assigned).to be true
    end
    
    it "tests the specific conditions that might cause feed_cat to be skipped" do
      # Test various conditions that could cause a chore to be skipped
      
      # Test 1: Age appropriateness
      expect(feed_cat.age_appropriate_for?(alice)).to be true
      expect(feed_cat.age_appropriate_for?(bob)).to be true
      
      # Test 2: Chore is active
      expect(feed_cat.active).to be true
      expect(feed_cat.chore_type).to eq("rotational")
      
      # Test 3: Children are active
      expect(alice.active).to be true
      expect(bob.active).to be true
      
      # Test 4: Family association
      expect(feed_cat.family_id).to eq(family.id)
      expect([alice.family_id, bob.family_id]).to all(eq(family.id))
      
      puts "\n=== CONDITION CHECKS ==="
      puts "Feed the Cat chore:"
      puts "  - Active: #{feed_cat.active}"
      puts "  - Type: #{feed_cat.chore_type}"
      puts "  - Min age: #{feed_cat.min_age || 'none'}"
      puts "  - Max age: #{feed_cat.max_age || 'none'}"
      puts "  - Family: #{feed_cat.family_id}"
      
      puts "Children:"
      [alice, bob].each do |child|
        puts "  - #{child.name}: active=#{child.active}, age=#{child.age}, family=#{child.family_id}"
        puts "    Age appropriate for feed_cat: #{feed_cat.age_appropriate_for?(child)}"
      end
    end
    
    it "reproduces the exact DailyChoreListGenerator workflow" do
      # Let's manually step through exactly what DailyChoreListGenerator does
      puts "\n=== REPRODUCING EXACT WORKFLOW ==="
      
      generator = DailyChoreListGenerator.new(family, Date.current)
      
      # This is what generate_for_all_children does:
      family.children.active.each do |child|
        puts "Processing child: #{child.name}"
        
        # Check if daily list already exists
        if child.daily_chore_lists.exists?(date: Date.current)
          puts "  - Daily list already exists, skipping"
          next
        end
        
        # Collect constant chores (we don't have any in this test)
        constant_chores = child.constant_chores.active.select { |chore| chore.age_appropriate_for?(child) }
        puts "  - Constant chores: #{constant_chores.map(&:title).join(', ')}"
        
        # Collect rotational chores
        rotation_assignments = ChoreRotationGenerator.new(family, Date.current).generate_rotational_assignments
        rotational_chores = rotation_assignments[child] || []
        puts "  - Rotational chores: #{rotational_chores.map(&:title).join(', ')}"
        
        # Create daily list
        daily_list = child.daily_chore_lists.create!(
          date: Date.current,
          generated_at: Time.current
        )
        puts "  - Created daily list: #{daily_list.id}"
        
        # Find or create chore list
        chore_list = child.chore_lists.find_or_create_by!(
          start_date: Date.current,
          interval: :daily
        )
        puts "  - Using chore list: #{chore_list.id}"
        
        # Create completions
        all_chores = constant_chores + rotational_chores
        all_chores.each do |chore|
          completion = chore_list.chore_completions.create!(
            chore: chore,
            child: child,
            assigned_date: Date.current,
            status: :pending
          )
          puts "  - Created completion: #{chore.title} -> #{child.name} (ID: #{completion.id})"
        end
      end
      
      # Final check
      final_completions = ChoreCompletion.includes(:chore, :child)
                                         .where(assigned_date: Date.current)
      puts "Final completions:"
      final_completions.each do |completion|
        puts "  - #{completion.child.name}: #{completion.chore.title}"
      end
      
      rotational_completions = final_completions.joins(:chore)
                                               .where(chores: { chore_type: :rotational })
      
      expect(rotational_completions.count).to eq(2) # Should have both chores
      expect(rotational_completions.map { |c| c.chore.title }).to include("Feed the Cat")
    end
  end
end