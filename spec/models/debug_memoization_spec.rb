require "rails_helper"

RSpec.describe "Debug Memoization Issue", type: :model do
  let(:family) { create(:family) }
  let!(:alice) { create(:child, family: family, first_name: "Alice", birth_date: 10.years.ago) }
  let!(:bob) { create(:child, family: family, first_name: "Bob", birth_date: 8.years.ago) }
  
  let!(:feed_cat) { create(:chore, family: family, title: "Feed the Cat", chore_type: :rotational, difficulty: :easy) }
  let!(:take_trash) { create(:chore, family: family, title: "Take Out Trash", chore_type: :rotational, difficulty: :easy) }
  
  describe "memoization debugging" do
    it "checks if memoization is working properly" do
      generator = DailyChoreListGenerator.new(family, Date.current)
      
      puts "\n=== DEBUGGING MEMOIZATION ==="
      
      # Call the private method directly to test memoization
      assignments1 = generator.send(:rotational_assignments_for_date)
      assignments2 = generator.send(:rotational_assignments_for_date)
      
      puts "First call assignments:"
      assignments1.each { |child, chores| puts "  #{child.name}: #{chores.map(&:title).join(', ')}" }
      
      puts "Second call assignments:"
      assignments2.each { |child, chores| puts "  #{child.name}: #{chores.map(&:title).join(', ')}" }
      
      puts "Same object? #{assignments1.object_id == assignments2.object_id}"
      
      # Check what each child gets when we call collect_rotational_chores
      puts "\nPer-child collection:"
      [alice, bob].each do |child|
        chores = generator.send(:collect_rotational_chores, child)
        puts "  #{child.name}: #{chores.map(&:title).join(', ')}"
      end
      
      expect(assignments1.object_id).to eq(assignments2.object_id)
      
      # The real test: ensure all rotational chores are distributed
      all_assigned_chores = assignments1.values.flatten
      all_rotational_chores = family.chores.active.rotational
      
      expect(all_assigned_chores.map(&:id).sort).to eq(all_rotational_chores.map(&:id).sort)
    end
    
    it "tests if the issue is in ChoreRotation record creation" do
      # Let's see if the issue is that ChoreRotation records are interfering
      puts "\n=== TESTING CHOREROTATION INTERFERENCE ==="
      
      # First, let's see what happens when we generate rotations
      rotation_gen = ChoreRotationGenerator.new(family, Date.current)
      assignments = rotation_gen.generate_rotational_assignments
      
      puts "Assignments from generator:"
      assignments.each { |child, chores| puts "  #{child.name}: #{chores.map(&:title).join(', ')}" }
      
      # Check if ChoreRotation records were created
      rotations_created = ChoreRotation.where(assigned_date: Date.current)
      puts "ChoreRotation records created: #{rotations_created.count}"
      rotations_created.each do |rotation|
        puts "  #{rotation.child.name} -> #{rotation.chore.title}"
      end
      
      # Now let's call it again and see if the results change
      puts "\nSecond call to generator:"
      rotation_gen2 = ChoreRotationGenerator.new(family, Date.current)
      assignments2 = rotation_gen2.generate_rotational_assignments
      
      assignments2.each { |child, chores| puts "  #{child.name}: #{chores.map(&:title).join(', ')}" }
      
      # Check total rotations now
      total_rotations = ChoreRotation.where(assigned_date: Date.current)
      puts "Total ChoreRotation records: #{total_rotations.count}"
      
      expect(assignments).to eq(assignments2)
    end
  end
end