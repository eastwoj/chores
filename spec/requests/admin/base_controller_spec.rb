require "rails_helper"

RSpec.describe "Admin Base Access Control", type: :request do
  let(:family) { create(:family) }
  let(:admin_role) { create(:role, name: "admin") }
  let(:parent_role) { create(:role, name: "parent") }
  let(:guardian_role) { create(:role, name: "guardian") }
  let(:other_role) { create(:role, name: "other") }

  # Test multiple admin routes to ensure base controller protection
  shared_examples "admin access control" do |path, method = :get|
    context "when not authenticated" do
      it "redirects to sign in page" do
        send(method, path)
        expect(response).to redirect_to(new_adult_session_path)
      end
    end

    context "with admin role" do
      let(:admin_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: admin_adult, role: admin_role)
        sign_in admin_adult
      end

      it "allows access" do
        send(method, path)
        expect(response).not_to redirect_to(root_path)
        expect(response).to have_http_status(:success)
      end
    end

    context "with parent role" do
      let(:parent_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: parent_adult, role: parent_role)
        sign_in parent_adult
      end

      it "allows access" do
        send(method, path)
        expect(response).not_to redirect_to(root_path)
        expect(response).to have_http_status(:success)
      end
    end

    context "with guardian role" do
      let(:guardian_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: guardian_adult, role: guardian_role)
        sign_in guardian_adult
      end

      it "allows access" do
        send(method, path)
        expect(response).not_to redirect_to(root_path)
        expect(response).to have_http_status(:success)
      end
    end

    context "with unauthorized role" do
      let(:regular_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: regular_adult, role: other_role)
        sign_in regular_adult
      end

      it "denies access and redirects to root" do
        send(method, path)
        expect(response).to redirect_to(root_path)
      end

      it "sets appropriate flash message" do
        send(method, path)
        follow_redirect!
        expect(flash[:alert]).to eq("You don't have permission to access the admin area.")
      end
    end

    context "with no roles" do
      let(:no_role_adult) { create(:adult, family: family) }

      before { sign_in no_role_adult }

      it "denies access and redirects to root" do
        send(method, path)
        expect(response).to redirect_to(root_path)
      end

      it "sets appropriate flash message" do
        send(method, path)
        follow_redirect!
        expect(flash[:alert]).to eq("You don't have permission to access the admin area.")
      end
    end
  end

  describe "admin dashboard routes" do
    include_examples "admin access control", "/admin"
    include_examples "admin access control", "/admin/dashboard"
  end
end