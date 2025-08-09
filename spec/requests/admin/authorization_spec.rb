require "rails_helper"

RSpec.describe "Admin Authorization", type: :request do
  let(:family) { Family.create!(name: "Test Family") }
  let(:admin_role) { Role.create!(name: "admin", description: "Admin role") }
  let(:parent_role) { Role.create!(name: "parent", description: "Parent role") }
  let(:guardian_role) { Role.create!(name: "guardian", description: "Guardian role") }
  let(:other_role) { Role.create!(name: "other", description: "Other role") }

  describe "GET /admin" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get "/admin"
        expect(response).to redirect_to(new_adult_session_path)
      end
    end

    context "with authorized roles" do
      %w[admin parent guardian].each do |role_name|
        context "when signed in as #{role_name}" do
          let(:adult) { Adult.create!(first_name: "Test", last_name: "User", email: "#{role_name}@test.com", password: "password123", family: family) }
          let(:role) { Role.find_or_create_by!(name: role_name, description: "#{role_name.capitalize} role") }

          before do
            AdultRole.create!(adult: adult, role: role)
            sign_in adult
          end

          it "allows access to admin dashboard" do
            get "/admin"
            expect(response).to have_http_status(:success)
            expect(response.body).to include("Family Dashboard")
          end
        end
      end
    end

    context "with unauthorized roles" do
      let(:regular_adult) { Adult.create!(first_name: "Regular", last_name: "User", email: "regular@test.com", password: "password123", family: family) }

      before do
        AdultRole.create!(adult: regular_adult, role: other_role)
        sign_in regular_adult
      end

      it "denies access and redirects to root" do
        get "/admin"
        expect(response).to redirect_to(root_path)
      end

      it "sets appropriate flash message" do
        get "/admin"
        follow_redirect!
        expect(flash[:alert]).to eq("You don't have permission to access the admin area.")
      end
    end

    context "with no roles" do
      let(:no_role_adult) { Adult.create!(first_name: "NoRole", last_name: "User", email: "norole@test.com", password: "password123", family: family) }

      before { sign_in no_role_adult }

      it "denies access and redirects to root" do
        get "/admin"
        expect(response).to redirect_to(root_path)
      end

      it "sets appropriate flash message" do
        get "/admin"
        follow_redirect!
        expect(flash[:alert]).to eq("You don't have permission to access the admin area.")
      end
    end
  end

  describe "GET /admin/dashboard" do
    context "authorized access" do
      let(:admin_adult) { Adult.create!(first_name: "Admin", last_name: "User", email: "admin@test.com", password: "password123", family: family) }

      before do
        AdultRole.create!(adult: admin_adult, role: admin_role)
        sign_in admin_adult
      end

      it "allows access to dashboard index" do
        get "/admin/dashboard"
        expect(response).to have_http_status(:success)
      end
    end

    context "unauthorized access" do
      let(:regular_adult) { Adult.create!(first_name: "Regular", last_name: "User", email: "regular@test.com", password: "password123", family: family) }

      before do
        AdultRole.create!(adult: regular_adult, role: other_role)
        sign_in regular_adult
      end

      it "denies access and redirects to root" do
        get "/admin/dashboard"
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "role changes during session" do
    let(:adult) { Adult.create!(first_name: "Test", last_name: "User", email: "test@test.com", password: "password123", family: family) }

    context "when adult loses admin role during active session" do
      before do
        adult_role = AdultRole.create!(adult: adult, role: admin_role)
        sign_in adult
        
        # Verify initial access
        get "/admin"
        expect(response).to have_http_status(:success)
        
        # Remove admin role
        adult_role.destroy
      end

      it "immediately denies access on next request" do
        get "/admin"
        expect(response).to redirect_to(root_path)
      end
    end

    context "when adult gains admin role during active session" do
      before do
        AdultRole.create!(adult: adult, role: other_role)
        sign_in adult
        
        # Verify initial denial
        get "/admin"
        expect(response).to redirect_to(root_path)
        
        # Add admin role
        AdultRole.create!(adult: adult, role: admin_role)
      end

      it "immediately grants access on next request" do
        get "/admin"
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "multiple roles" do
    let(:multi_role_adult) { Adult.create!(first_name: "Multi", last_name: "Role", email: "multi@test.com", password: "password123", family: family) }

    before do
      AdultRole.create!(adult: multi_role_adult, role: admin_role)
      AdultRole.create!(adult: multi_role_adult, role: parent_role)
      sign_in multi_role_adult
    end

    it "allows access with multiple authorized roles" do
      get "/admin"
      expect(response).to have_http_status(:success)
    end

    it "correctly reports multiple roles" do
      expect(multi_role_adult.has_role?("admin")).to be true
      expect(multi_role_adult.has_role?("parent")).to be true
      expect(multi_role_adult.has_role?("guardian")).to be false
    end
  end
end