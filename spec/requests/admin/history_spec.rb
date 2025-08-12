require "rails_helper"

RSpec.describe "Admin::History", type: :request do
  let(:family) { create(:family) }
  let(:admin_role) { create(:role, name: "admin") }
  let(:admin_adult) { create(:adult, family: family) }
  
  let!(:alice) { create(:child, family: family, first_name: "Alice", birth_date: 10.years.ago) }
  let!(:bob) { create(:child, family: family, first_name: "Bob", birth_date: 8.years.ago) }
  
  let!(:easy_chore) { create(:chore, family: family, title: "Make Bed", difficulty: :easy) }
  let!(:hard_chore) { create(:chore, family: family, title: "Clean Garage", difficulty: :hard) }
  
  before do
    create(:adult_role, adult: admin_adult, role: admin_role)
    sign_in admin_adult
  end

  describe "GET /admin/history" do
    let!(:chore_list_alice) { create(:chore_list, child: alice, start_date: Date.current) }
    let!(:chore_list_bob) { create(:chore_list, child: bob, start_date: Date.current) }
    
    let!(:completion1) do 
      create(:chore_completion, 
             child: alice, 
             chore: easy_chore, 
             chore_list: chore_list_alice,
             status: :completed, 
             assigned_date: Date.current,
             completed_at: 1.hour.ago)
    end
    
    let!(:completion2) do
      create(:chore_completion, 
             child: bob, 
             chore: hard_chore, 
             chore_list: chore_list_bob,
             status: :pending, 
             assigned_date: Date.current - 1.day)
    end
    
    let!(:completion3) do
      create(:chore_completion, 
             child: alice, 
             chore: hard_chore, 
             chore_list: chore_list_alice,
             status: :reviewed_satisfactory, 
             assigned_date: Date.current - 2.days,
             completed_at: 2.days.ago,
             reviewed_at: 1.day.ago,
             reviewed_by: admin_adult)
    end

    it "displays chore history with filtering options" do
      get admin_history_index_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Chore History")
      expect(response.body).to include("Alice")
      expect(response.body).to include("Bob") 
      expect(response.body).to include("Make Bed")
      expect(response.body).to include("Clean Garage")
    end

    it "filters by date range" do
      get admin_history_index_path, params: { 
        start_date: Date.current - 1.day, 
        end_date: Date.current 
      }
      
      expect(response).to have_http_status(:success)
      # Should include recent completions
      expect(response.body).to include("Make Bed")
      # Should exclude older completions (completion3 is from 2 days ago)
    end

    it "filters by specific child" do
      get admin_history_index_path, params: { child_id: alice.id }
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Alice")
      # Should not include Bob's chores in the table
    end

    it "filters by status" do
      get admin_history_index_path, params: { status: "completed" }
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Completed")
    end

    it "displays summary statistics" do
      get admin_history_index_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Total Chores")
      expect(response.body).to include("Completed")
      expect(response.body).to include("Pending")
      expect(response.body).to include("Satisfactory")
    end

    it "shows completion and review timestamps" do
      get admin_history_index_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include(completion1.completed_at.strftime("%m/%d"))
      expect(response.body).to include(completion3.reviewed_at.strftime("%m/%d"))
      expect(response.body).to include(admin_adult.first_name)
    end

    it "displays chore difficulty and type" do
      get admin_history_index_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Easy")
      expect(response.body).to include("Hard")
    end

    it "shows empty state when no results" do
      # Filter to a date range with no chores
      get admin_history_index_path, params: { 
        start_date: Date.current + 10.days, 
        end_date: Date.current + 20.days 
      }
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("No chore history found")
    end

    context "when not authenticated" do
      before { sign_out admin_adult }
      
      it "redirects to sign in page" do
        get admin_history_index_path
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
        get admin_history_index_path
        expect(response).to redirect_to(root_path)
      end
    end
  end
end