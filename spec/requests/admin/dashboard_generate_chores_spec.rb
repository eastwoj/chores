require "rails_helper"

RSpec.describe "Admin::Dashboard Generate Chores", type: :request do
  let(:family) { create(:family) }
  let(:admin_role) { create(:role, name: "admin") }
  let(:admin_adult) { create(:adult, family: family) }
  
  let!(:children) do
    [
      create(:child, family: family, first_name: "Alice", birth_date: 10.years.ago),
      create(:child, family: family, first_name: "Bob", birth_date: 8.years.ago),
      create(:child, family: family, first_name: "Charlie", birth_date: 12.years.ago)
    ]
  end

  # Create constant chores that should be assigned to ALL children
  let!(:constant_easy) { create(:chore, family: family, title: "Make Bed", chore_type: :constant, difficulty: :easy) }
  let!(:constant_medium) { create(:chore, family: family, title: "Brush Teeth", chore_type: :constant, difficulty: :medium) }
  
  # Create rotational chores that should be distributed equally by difficulty  
  let!(:rotation_easy_1) { create(:chore, family: family, title: "Take Out Trash", chore_type: :rotational, difficulty: :easy) }
  let!(:rotation_easy_2) { create(:chore, family: family, title: "Feed Pets", chore_type: :rotational, difficulty: :easy) }
  let!(:rotation_medium_1) { create(:chore, family: family, title: "Vacuum Living Room", chore_type: :rotational, difficulty: :medium) }
  let!(:rotation_medium_2) { create(:chore, family: family, title: "Clean Bathroom", chore_type: :rotational, difficulty: :medium) }
  let!(:rotation_hard_1) { create(:chore, family: family, title: "Organize Garage", chore_type: :rotational, difficulty: :hard) }
  let!(:rotation_hard_2) { create(:chore, family: family, title: "Wash Car", chore_type: :rotational, difficulty: :hard) }

  before do
    create(:adult_role, adult: admin_adult, role: admin_role)
    
    # Create chore assignments for constant chores to all children
    children.each do |child|
      create(:chore_assignment, child: child, chore: constant_easy)
      create(:chore_assignment, child: child, chore: constant_medium)
    end
    
    sign_in admin_adult
  end

  describe "POST /admin/dashboard/generate_chores" do
    it "generates today's chores successfully" do
      expect {
        post "/admin/dashboard/generate_chores"
      }.to change { ChoreCompletion.where(assigned_date: Date.current).count }
      
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:notice]).to eq("Today's chores have been generated successfully!")
    end

    it "assigns ALL constant chores to ALL children" do
      post "/admin/dashboard/generate_chores"
      
      children.each do |child|
        constant_completions = ChoreCompletion.joins(:chore)
                                            .where(child: child, assigned_date: Date.current)
                                            .where(chores: { chore_type: :constant })
        
        expect(constant_completions.count).to eq(2), "Child #{child.first_name} should have 2 constant chores"
        
        # Check specific constant chores are assigned
        assigned_chore_ids = constant_completions.pluck(:chore_id)
        expect(assigned_chore_ids).to include(constant_easy.id, constant_medium.id)
      end
    end

    it "assigns ALL rotational chores with equal difficulty distribution" do
      post "/admin/dashboard/generate_chores"
      
      # Get all rotational chore completions for today
      rotational_completions = ChoreCompletion.joins(:chore)
                                            .where(assigned_date: Date.current)
                                            .where(chores: { chore_type: :rotational })
      
      # All rotational chores should be assigned (none missed)
      assigned_chore_ids = rotational_completions.pluck(:chore_id).sort
      expected_rotational_ids = [rotation_easy_1.id, rotation_easy_2.id, 
                                rotation_medium_1.id, rotation_medium_2.id,
                                rotation_hard_1.id, rotation_hard_2.id].sort
      
      expect(assigned_chore_ids).to eq(expected_rotational_ids), "All rotational chores should be assigned"
      
      # Check difficulty distribution is equal across children
      difficulty_weights_by_child = {}
      children.each do |child|
        child_rotational = rotational_completions.where(child: child)
        total_weight = child_rotational.joins(:chore).sum do |completion|
          completion.chore.difficulty_weight
        end
        difficulty_weights_by_child[child.id] = total_weight
      end
      
      # All children should have similar difficulty weights (within 1 point of each other)
      min_weight = difficulty_weights_by_child.values.min
      max_weight = difficulty_weights_by_child.values.max
      
      expect(max_weight - min_weight).to be <= 1,
             "Difficulty distribution should be balanced. Weights: #{difficulty_weights_by_child}"
    end

    it "does not duplicate chores if already generated for today" do
      # Generate chores once
      post "/admin/dashboard/generate_chores"
      initial_count = ChoreCompletion.where(assigned_date: Date.current).count
      
      # Try to generate again - should be idempotent
      post "/admin/dashboard/generate_chores"
      final_count = ChoreCompletion.where(assigned_date: Date.current).count
      
      expect(final_count).to eq(initial_count), "Should not create duplicate chores for same day"
      expect(flash[:notice]).to eq("Today's chores have been generated successfully!")
    end

    it "only assigns age-appropriate chores" do
      # Create age-restricted chore for teenagers only
      teen_chore = create(:chore, family: family, title: "Drive to Store", 
                         chore_type: :constant, min_age: 16)
      
      # Assign to all children
      children.each { |child| create(:chore_assignment, child: child, chore: teen_chore) }
      
      post "/admin/dashboard/generate_chores"
      
      # No children under 16 should have this chore
      children.each do |child|
        next if child.age >= 16
        
        completions = ChoreCompletion.where(child: child, chore: teen_chore, assigned_date: Date.current)
        expect(completions.count).to eq(0), "Child #{child.first_name} (age #{child.age}) should not have age-restricted chore"
      end
    end

    context "when not authenticated" do
      before { sign_out admin_adult }
      
      it "redirects to sign in page" do
        post "/admin/dashboard/generate_chores"
        expect(response).to redirect_to(new_adult_session_path)
      end
    end

    context "when authenticated but not authorized" do
      let(:other_role) { create(:role, name: "other") }
      let(:regular_adult) { create(:adult, family: family) }
      
      before do
        create(:adult_role, adult: regular_adult, role: other_role)
        sign_out admin_adult
        sign_in regular_adult
      end
      
      it "redirects to root path" do
        post "/admin/dashboard/generate_chores"
        expect(response).to redirect_to(root_path)
      end
    end
  end
end