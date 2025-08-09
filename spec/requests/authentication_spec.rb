require "rails_helper"

RSpec.describe "Authentication and Authorization", type: :request do
  let(:family) { create(:family) }
  let(:admin_role) { create(:role, name: "admin") }
  let(:other_role) { create(:role, name: "other") }

  describe "sign in flow with role-based access" do
    let(:admin_adult) { create(:adult, family: family, email: "admin@test.com") }
    let(:regular_adult) { create(:adult, family: family, email: "regular@test.com") }

    before do
      create(:adult_role, adult: admin_adult, role: admin_role)
      create(:adult_role, adult: regular_adult, role: other_role)
    end

    context "admin adult signs in" do
      it "redirects to admin dashboard after successful authentication" do
        post "/adults/sign_in", params: {
          adult: {
            email: admin_adult.email,
            password: admin_adult.password
          }
        }

        expect(response).to redirect_to(admin_root_path)
        
        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Family Dashboard")
      end
    end

    context "regular adult signs in" do
      it "can authenticate but cannot access admin area" do
        # Sign in successfully
        post "/adults/sign_in", params: {
          adult: {
            email: regular_adult.email,
            password: regular_adult.password
          }
        }

        expect(response).to redirect_to(admin_root_path)
        
        # But accessing admin is denied
        follow_redirect!
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "role changes during session" do
    let(:adult) { create(:adult, family: family) }

    context "when adult loses admin role during active session" do
      before do
        # Start with admin role
        adult_role = create(:adult_role, adult: adult, role: admin_role)
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
        # Start without admin role
        create(:adult_role, adult: adult, role: other_role)
        sign_in adult
        
        # Verify initial denial
        get "/admin"
        expect(response).to redirect_to(root_path)
        
        # Add admin role
        create(:adult_role, adult: adult, role: admin_role)
      end

      it "immediately grants access on next request" do
        get "/admin"
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "multiple roles" do
    let(:admin_parent_adult) { create(:adult, family: family) }
    let(:parent_role) { create(:role, name: "parent") }

    before do
      create(:adult_role, adult: admin_parent_adult, role: admin_role)
      create(:adult_role, adult: admin_parent_adult, role: parent_role)
      sign_in admin_parent_adult
    end

    it "allows access with multiple authorized roles" do
      get "/admin"
      expect(response).to have_http_status(:success)
    end

    it "correctly reports multiple roles" do
      expect(admin_parent_adult.has_role?("admin")).to be true
      expect(admin_parent_adult.has_role?("parent")).to be true
      expect(admin_parent_adult.has_role?("guardian")).to be false
    end
  end

  describe "edge cases" do
    context "deleted adult account" do
      let(:admin_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: admin_adult, role: admin_role)
        sign_in admin_adult
        
        # Verify access works
        get "/admin"
        expect(response).to have_http_status(:success)
      end

      it "loses access when account is deleted" do
        # Delete the adult account
        adult_id = admin_adult.id
        admin_adult.destroy
        
        # Session should be invalid
        get "/admin"
        expect(response).to redirect_to(new_adult_session_path)
      end
    end

    context "role with same name but different ID" do
      let(:adult) { create(:adult, family: family) }
      let(:original_admin_role) { create(:role, name: "admin", description: "Original") }
      let(:new_admin_role) { create(:role, name: "admin", description: "New") }

      it "works correctly with role name lookup regardless of ID" do
        # Assign original admin role
        create(:adult_role, adult: adult, role: original_admin_role)
        sign_in adult

        get "/admin"
        expect(response).to have_http_status(:success)

        # Change to new admin role with same name
        adult.adult_roles.destroy_all
        create(:adult_role, adult: adult, role: new_admin_role)

        get "/admin"
        expect(response).to have_http_status(:success)
      end
    end
  end
end