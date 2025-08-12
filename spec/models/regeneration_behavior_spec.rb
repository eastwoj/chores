require "rails_helper"

RSpec.describe "Chore Regeneration Behavior", type: :model do
  let(:family) { create(:family) }
  let!(:alice) { create(:child, family: family, first_name: "Alice") }
  let!(:bob) { create(:child, family: family, first_name: "Bob") }
  
  let!(:constant_chore) { create(:chore, family: family, title: "Brush Teeth", chore_type: :constant, difficulty: :easy) }
  let!(:rotational_chore1) { create(:chore, family: family, title: "Feed Cat", chore_type: :rotational, difficulty: :easy) }
  let!(:rotational_chore2) { create(:chore, family: family, title: "Take Trash", chore_type: :rotational, difficulty: :medium) }
  
  # Assign constant chore to Alice
  let!(:constant_assignment) { create(:chore_assignment, chore: constant_chore, child: alice, active: true) }
  
  describe "regeneration behavior" do
    it "clears existing assignments and creates new ones when called multiple times" do
      # Initial generation
      family.generate_daily_chore_lists(Date.current)
      
      initial_completions = ChoreCompletion.where(assigned_date: Date.current)
      initial_rotations = ChoreRotation.where(assigned_date: Date.current)
      
      expect(initial_completions.count).to be > 0
      expect(initial_rotations.count).to be > 0
      
      # Capture which child got which rotational chore initially
      alice_initial_rotational = initial_completions.joins(:chore)
                                                  .where(child: alice, chores: { chore_type: :rotational })
                                                  .pluck(:chore_id)
      bob_initial_rotational = initial_completions.joins(:chore)
                                                .where(child: bob, chores: { chore_type: :rotational })
                                                .pluck(:chore_id)
      
      puts "Initial assignments:"
      puts "Alice rotational: #{initial_completions.joins(:chore).where(child: alice, chores: { chore_type: :rotational }).pluck('chores.title')}"
      puts "Bob rotational: #{initial_completions.joins(:chore).where(child: bob, chores: { chore_type: :rotational }).pluck('chores.title')}"
      
      # Store initial completion IDs
      initial_completion_ids = initial_completions.pluck(:id).sort
      
      # Regenerate chores (simulating button click)
      family.generate_daily_chore_lists(Date.current)
      
      # Check that old records were cleared and new ones created
      final_completions = ChoreCompletion.where(assigned_date: Date.current)
      final_completion_ids = final_completions.pluck(:id).sort
      
      # The IDs should be completely different (old destroyed, new created)
      expect(final_completion_ids).not_to eq(initial_completion_ids)
      
      puts "After regeneration:"
      puts "Alice rotational: #{final_completions.joins(:chore).where(child: alice, chores: { chore_type: :rotational }).pluck('chores.title')}"
      puts "Bob rotational: #{final_completions.joins(:chore).where(child: bob, chores: { chore_type: :rotational }).pluck('chores.title')}"
      
      # But we should still have the same number of total assignments
      expect(final_completions.count).to eq(initial_completions.count)
      
      # All rotational chores should still be assigned
      assigned_rotational_chores = final_completions.joins(:chore)
                                                  .where(chores: { chore_type: :rotational })
                                                  .pluck(:chore_id).sort
      expected_rotational_chores = [rotational_chore1.id, rotational_chore2.id].sort
      
      expect(assigned_rotational_chores).to eq(expected_rotational_chores)
      
      # Constant chores should still be assigned correctly
      alice_constant = final_completions.joins(:chore)
                                       .where(child: alice, chores: { chore_type: :constant })
                                       .exists?
      expect(alice_constant).to be true
    end
    
    it "allows adding new chores and regenerating to include them" do
      # Initial generation with 2 rotational chores
      family.generate_daily_chore_lists(Date.current)
      
      initial_count = ChoreCompletion.where(assigned_date: Date.current).count
      
      # Add a new rotational chore
      new_chore = create(:chore, family: family, title: "New Rotational Task", chore_type: :rotational, difficulty: :hard)
      
      # Regenerate chores
      family.generate_daily_chore_lists(Date.current)
      
      final_completions = ChoreCompletion.where(assigned_date: Date.current)
      
      # Should now have one more chore completion
      expect(final_completions.count).to eq(initial_count + 1)
      
      # The new chore should be assigned
      new_chore_assigned = final_completions.joins(:chore)
                                          .where(chores: { title: "New Rotational Task" })
                                          .exists?
      expect(new_chore_assigned).to be true
    end
    
    it "works correctly when activating previously inactive chores" do
      # Create an inactive chore
      inactive_chore = create(:chore, family: family, title: "Inactive Task", chore_type: :rotational, difficulty: :medium, active: false)
      
      # Initial generation (should not include inactive chore)
      family.generate_daily_chore_lists(Date.current)
      
      initial_completions = ChoreCompletion.where(assigned_date: Date.current)
      inactive_assigned_initially = initial_completions.joins(:chore)
                                                      .where(chores: { title: "Inactive Task" })
                                                      .exists?
      expect(inactive_assigned_initially).to be false
      
      # Activate the chore
      inactive_chore.update!(active: true)
      
      # Regenerate chores
      family.generate_daily_chore_lists(Date.current)
      
      final_completions = ChoreCompletion.where(assigned_date: Date.current)
      inactive_assigned_finally = final_completions.joins(:chore)
                                                  .where(chores: { title: "Inactive Task" })
                                                  .exists?
      
      # Now it should be assigned
      expect(inactive_assigned_finally).to be true
    end
  end
end