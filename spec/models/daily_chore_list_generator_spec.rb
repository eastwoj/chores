require "rails_helper"

RSpec.describe DailyChoreListGenerator, type: :model do
  let(:family) { create(:family) }
  let!(:child1) { create(:child, family: family, first_name: "Alice", birth_date: 10.years.ago) }
  let!(:child2) { create(:child, family: family, first_name: "Bob", birth_date: 8.years.ago) }
  let!(:child3) { create(:child, family: family, first_name: "Charlie", birth_date: 12.years.ago) }
  
  # Create constant chores
  let!(:constant_easy) { create(:chore, family: family, chore_type: :constant, difficulty: :easy, title: "Make Bed") }
  let!(:constant_medium) { create(:chore, family: family, chore_type: :constant, difficulty: :medium, title: "Brush Teeth") }
  
  # Create rotational chores with various difficulties
  let!(:rotation_easy_1) { create(:chore, family: family, chore_type: :rotational, difficulty: :easy, title: "Take Out Trash") }
  let!(:rotation_easy_2) { create(:chore, family: family, chore_type: :rotational, difficulty: :easy, title: "Feed Pets") }
  let!(:rotation_medium_1) { create(:chore, family: family, chore_type: :rotational, difficulty: :medium, title: "Vacuum Living Room") }
  let!(:rotation_hard_1) { create(:chore, family: family, chore_type: :rotational, difficulty: :hard, title: "Organize Garage") }
  
  let(:generator) { described_class.new(family, Date.current) }
  
  before do
    # Create chore assignments for constant chores
    [child1, child2, child3].each do |child|
      create(:chore_assignment, child: child, chore: constant_easy)
      create(:chore_assignment, child: child, chore: constant_medium)
    end
  end

  describe "#generate_for_all_children" do
    it "generates daily chore lists for all active children" do
      expect { generator.generate_for_all_children }.to change { DailyChoreList.count }.by(3)
      
      [child1, child2, child3].each do |child|
        expect(child.daily_chore_lists.exists?(date: Date.current)).to be true
      end
    end

    it "assigns all constant chores to all children" do
      generator.generate_for_all_children
      
      [child1, child2, child3].each do |child|
        constant_completions = ChoreCompletion.joins(:chore)
                                            .where(child: child, assigned_date: Date.current)
                                            .where(chores: { chore_type: :constant })
        
        expect(constant_completions.count).to eq(2), "Child #{child.first_name} should have 2 constant chores"
        
        # Check specific constant chores are assigned
        assigned_chore_ids = constant_completions.pluck(:chore_id)
        expect(assigned_chore_ids).to include(constant_easy.id, constant_medium.id)
      end
    end

    it "assigns all rotational chores with balanced difficulty distribution" do
      generator.generate_for_all_children
      
      # All rotational chores should be assigned
      total_rotational_completions = ChoreCompletion.joins(:chore)
                                                  .where(assigned_date: Date.current)
                                                  .where(chores: { chore_type: :rotational })
      
      assigned_chore_ids = total_rotational_completions.pluck(:chore_id).sort
      expected_ids = [rotation_easy_1.id, rotation_easy_2.id, rotation_medium_1.id, rotation_hard_1.id].sort
      
      expect(assigned_chore_ids).to eq(expected_ids), "All rotational chores should be assigned"
      
      # Check difficulty weights are balanced
      difficulty_weights = {}
      [child1, child2, child3].each do |child|
        child_rotational = total_rotational_completions.where(child: child)
        weight = child_rotational.joins(:chore).sum { |completion| completion.chore.difficulty_weight }
        difficulty_weights[child.id] = weight
      end
      
      # All children should have similar difficulty weights (within 1 point)
      min_weight = difficulty_weights.values.min
      max_weight = difficulty_weights.values.max
      
      expect(max_weight - min_weight).to be <= 1,
             "Rotational chore difficulty should be balanced. Weights: #{difficulty_weights}"
    end

    it "is idempotent - does not create duplicates" do
      generator.generate_for_all_children
      initial_count = ChoreCompletion.where(assigned_date: Date.current).count
      
      # Run again
      generator.generate_for_all_children
      final_count = ChoreCompletion.where(assigned_date: Date.current).count
      
      expect(final_count).to eq(initial_count), "Generator should be idempotent"
    end

    it "respects age restrictions" do
      # Create age-restricted chore
      teen_chore = create(:chore, family: family, chore_type: :constant, min_age: 16, title: "Drive to Store")
      create(:chore_assignment, child: child1, chore: teen_chore) # child1 is 10 years old
      
      generator.generate_for_all_children
      
      # Child1 should not have the teen chore assigned
      completions = ChoreCompletion.where(child: child1, chore: teen_chore, assigned_date: Date.current)
      expect(completions.count).to eq(0), "Age-inappropriate chore should not be assigned"
    end
  end
end