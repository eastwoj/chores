require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:family) { create(:family) }
  let(:admin_role) { create(:role, name: "admin") }
  let(:parent_role) { create(:role, name: "parent") }
  let(:guardian_role) { create(:role, name: "guardian") }
  let(:other_role) { create(:role, name: "other") }

  describe "GET /admin" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get "/admin"
        expect(response).to redirect_to(new_adult_session_path)
      end
    end

    context "when signed in as admin" do
      let(:admin_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: admin_adult, role: admin_role)
        sign_in admin_adult
      end

      it "allows access to admin dashboard" do
        get "/admin"
        expect(response).to have_http_status(:success)
      end

      it "renders the dashboard template" do
        get "/admin"
        expect(response).to render_template(:index)
      end

      it "assigns @family" do
        get "/admin"
        expect(assigns(:family)).to eq(family)
      end

      it "assigns @children" do
        child = create(:child, family: family)
        get "/admin"
        expect(assigns(:children)).to include(child)
      end
    end

    context "when signed in as parent" do
      let(:parent_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: parent_adult, role: parent_role)
        sign_in parent_adult
      end

      it "allows access to admin dashboard" do
        get "/admin"
        expect(response).to have_http_status(:success)
      end

      it "renders the dashboard template" do
        get "/admin"
        expect(response).to render_template(:index)
      end
    end

    context "when signed in as guardian" do
      let(:guardian_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: guardian_adult, role: guardian_role)
        sign_in guardian_adult
      end

      it "allows access to admin dashboard" do
        get "/admin"
        expect(response).to have_http_status(:success)
      end

      it "renders the dashboard template" do
        get "/admin"
        expect(response).to render_template(:index)
      end
    end

    context "when signed in as adult without authorized role" do
      let(:regular_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: regular_adult, role: other_role)
        sign_in regular_adult
      end

      it "denies access and redirects to root" do
        get "/admin"
        expect(response).to redirect_to(root_path)
      end

      it "sets error flash message" do
        get "/admin"
        follow_redirect!
        expect(flash[:alert]).to eq("You don't have permission to access the admin area.")
      end
    end

    context "when signed in as adult with no roles" do
      let(:no_role_adult) { create(:adult, family: family) }

      before { sign_in no_role_adult }

      it "denies access and redirects to root" do
        get "/admin"
        expect(response).to redirect_to(root_path)
      end

      it "sets error flash message" do
        get "/admin"
        follow_redirect!
        expect(flash[:alert]).to eq("You don't have permission to access the admin area.")
      end
    end
  end

  describe "GET /admin/dashboard" do
    context "when signed in as admin" do
      let(:admin_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: admin_adult, role: admin_role)
        sign_in admin_adult
      end

      it "allows access to dashboard index" do
        get "/admin/dashboard"
        expect(response).to have_http_status(:success)
      end

      it "renders the dashboard index template" do
        get "/admin/dashboard"
        expect(response).to render_template(:index)
      end
    end

    context "when signed in as adult without authorized role" do
      let(:regular_adult) { create(:adult, family: family) }

      before do
        create(:adult_role, adult: regular_adult, role: other_role)
        sign_in regular_adult
      end

      it "denies access and redirects to root" do
        get "/admin/dashboard"
        expect(response).to redirect_to(root_path)
      end
    end
  end
end