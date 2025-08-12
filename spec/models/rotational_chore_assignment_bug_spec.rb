require "rails_helper"

RSpec.describe "Rotational Chore Assignment Bug", type: :model do
  let(:family) { create(:family) }
  let!(:alice) { create(:child, family: family, first_name: "Alice", birth_date: 10.years.ago) }
  let!(:bob) { create(:child, family: family, first_name: "Bob", birth_date: 8.years.ago) }
  
  # Create the exact scenario from production
  let!(:feed_cat) { create(:chore, family: family, title: "Feed the Cat", chore_type: :rotational, difficulty: :easy) }
  let!(:take_out_trash) { create(:chore, family: family, title: "Take Out Trash", chore_type: :rotational, difficulty: :easy) }
  let!(:vacuum_living_room) { create(:chore, family: family, title: "Vacuum Living Room", chore_type: :rotational, difficulty: :medium) }
  let!(:clean_bathroom) { create(:chore, family: family, title: "Clean Bathroom", chore_type: :rotational, difficulty: :medium) }
  let!(:organize_garage) { create(:chore, family: family, title: "Organize Garage", chore_type: :rotational, difficulty: :hard) }
  
  let(:generator) { DailyChoreListGenerator.new(family, Date.current) }
  
  describe "ALL rotational chores must be assigned" do
    it "assigns every single rotational chore to some child" do
      generator.generate_for_all_children
      
      # Get all rotational chores for the family
      all_rotational_chores = family.chores.active.rotational
      
      # Get all chore completions for today  
      assigned_completions = ChoreCompletion.joins(:chore)
                                          .where(assigned_date: Date.current)
                                          .where(chores: { family: family, chore_type: :rotational })
      
      assigned_chore_ids = assigned_completions.pluck(:chore_id)
      expected_chore_ids = all_rotational_chores.pluck(:id)
      
      missing_chores = all_rotational_chores.where.not(id: assigned_chore_ids)
      
      expect(missing_chores).to be_empty, 
             "These rotational chores were NOT assigned: #{missing_chores.pluck(:title).join(', ')}"
      
      expect(assigned_chore_ids.sort).to eq(expected_chore_ids.sort), 
             "Expected all rotational chores to be assigned"
    end
    
    it "specifically assigns 'Feed the Cat' chore to one of the children" do
      generator.generate_for_all_children
      
      feed_cat_assignments = ChoreCompletion.joins(:chore)
                                          .where(assigned_date: Date.current)
                                          .where(chores: { title: "Feed the Cat" })
      
      expect(feed_cat_assignments.count).to eq(1), 
             "Feed the Cat should be assigned to exactly one child"
      
      assigned_child = feed_cat_assignments.first.child
      expect([alice.id, bob.id]).to include(assigned_child.id),
             "Feed the Cat should be assigned to either Alice or Bob"
    end
    
    it "assigns each rotational chore exactly once (no duplicates, no missing)" do
      generator.generate_for_all_children
      
      all_rotational_chores = family.chores.active.rotational
      
      all_rotational_chores.each do |chore|
        assignments = ChoreCompletion.joins(:chore)
                                   .where(assigned_date: Date.current)
                                   .where(chore: chore)
        
        expect(assignments.count).to eq(1), 
               "Chore '#{chore.title}' should be assigned exactly once, but was assigned #{assignments.count} times"
      end
    end
    
    it "ensures balanced workload despite complete assignment coverage" do
      generator.generate_for_all_children
      
      alice_rotational = ChoreCompletion.joins(:chore)
                                       .where(child: alice, assigned_date: Date.current)
                                       .where(chores: { chore_type: :rotational })
      
      bob_rotational = ChoreCompletion.joins(:chore)
                                     .where(child: bob, assigned_date: Date.current)
                                     .where(chores: { chore_type: :rotational })
      
      alice_weight = alice_rotational.joins(:chore).sum { |completion| completion.chore.difficulty_weight }
      bob_weight = bob_rotational.joins(:chore).sum { |completion| completion.chore.difficulty_weight }
      
      # Both children should have some chores
      expect(alice_rotational.count).to be > 0, "Alice should have at least one rotational chore"
      expect(bob_rotational.count).to be > 0, "Bob should have at least one rotational chore"
      
      # Difficulty should be balanced (within 1 point)
      expect((alice_weight - bob_weight).abs).to be <= 1,
             "Difficulty should be balanced. Alice: #{alice_weight}, Bob: #{bob_weight}"
    end
  end
  
  describe "edge cases that might cause missing assignments" do
    it "handles odd numbers of rotational chores correctly" do
      # Add one more chore to make it 6 total (odd scenario)
      create(:chore, family: family, title: "Water Plants", chore_type: :rotational, difficulty: :easy)
      
      generator.generate_for_all_children
      
      all_rotational_chores = family.chores.active.rotational
      assigned_completions = ChoreCompletion.joins(:chore)
                                          .where(assigned_date: Date.current)
                                          .where(chores: { family: family, chore_type: :rotational })
      
      expect(assigned_completions.count).to eq(all_rotational_chores.count),
             "All rotational chores should be assigned even with odd numbers"
    end
    
    it "handles age restrictions without losing chores" do
      # Make one chore age-restricted
      feed_cat.update!(min_age: 15) # Neither Alice (10) nor Bob (8) can do this
      
      generator.generate_for_all_children
      
      # Feed cat should not be assigned due to age restriction
      feed_cat_assignments = ChoreCompletion.where(chore: feed_cat, assigned_date: Date.current)
      expect(feed_cat_assignments).to be_empty, "Age-restricted chores should not be assigned"
      
      # But all OTHER rotational chores should still be assigned
      other_chores = family.chores.active.rotational.where.not(id: feed_cat.id)
      other_assignments = ChoreCompletion.joins(:chore)
                                       .where(assigned_date: Date.current)
                                       .where(chores: { family: family, chore_type: :rotational })
                                       .where.not(chore: feed_cat)
      
      expect(other_assignments.count).to eq(other_chores.count),
             "All age-appropriate rotational chores should still be assigned"
    end
  end
end