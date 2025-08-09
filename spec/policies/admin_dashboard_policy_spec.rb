require "rails_helper"

RSpec.describe AdminDashboardPolicy, type: :policy do
  let(:family) { create(:family) }
  let(:admin_role) { create(:role, name: "admin") }
  let(:parent_role) { create(:role, name: "parent") }
  let(:guardian_role) { create(:role, name: "guardian") }
  let(:other_role) { create(:role, name: "other") }

  describe "for admin adult" do
    let(:admin_adult) { create(:adult, family: family) }
    before { create(:adult_role, adult: admin_adult, role: admin_role) }

    it { is_expected.to permit(admin_adult, :admin_dashboard) }
  end

  describe "for parent adult" do
    let(:parent_adult) { create(:adult, family: family) }
    before { create(:adult_role, adult: parent_adult, role: parent_role) }

    it { is_expected.to permit(parent_adult, :admin_dashboard) }
  end

  describe "for guardian adult" do
    let(:guardian_adult) { create(:adult, family: family) }
    before { create(:adult_role, adult: guardian_adult, role: guardian_role) }

    it { is_expected.to permit(guardian_adult, :admin_dashboard) }
  end

  describe "for adult without authorized roles" do
    let(:regular_adult) { create(:adult, family: family) }
    before { create(:adult_role, adult: regular_adult, role: other_role) }

    it { is_expected.to_not permit(regular_adult, :admin_dashboard) }
  end

  describe "for adult with no roles" do
    let(:no_role_adult) { create(:adult, family: family) }

    it { is_expected.to_not permit(no_role_adult, :admin_dashboard) }
  end

  describe "for non-adult user (child)" do
    let(:child) { create(:child, family: family) }

    it { is_expected.to_not permit(child, :admin_dashboard) }
  end

  describe "for nil user" do
    it { is_expected.to_not permit(nil, :admin_dashboard) }
  end

  describe "permissions" do
    let(:admin_adult) { create(:adult, family: family) }
    let(:parent_adult) { create(:adult, family: family) }
    let(:guardian_adult) { create(:adult, family: family) }
    let(:regular_adult) { create(:adult, family: family) }

    before do
      create(:adult_role, adult: admin_adult, role: admin_role)
      create(:adult_role, adult: parent_adult, role: parent_role)
      create(:adult_role, adult: guardian_adult, role: guardian_role)
      create(:adult_role, adult: regular_adult, role: other_role)
    end

    describe "index?" do
      it "allows admin to view dashboard" do
        expect(AdminDashboardPolicy.new(admin_adult, :admin_dashboard).index?).to be true
      end

      it "allows parent to view dashboard" do
        expect(AdminDashboardPolicy.new(parent_adult, :admin_dashboard).index?).to be true
      end

      it "allows guardian to view dashboard" do
        expect(AdminDashboardPolicy.new(guardian_adult, :admin_dashboard).index?).to be true
      end

      it "denies regular adult to view dashboard" do
        expect(AdminDashboardPolicy.new(regular_adult, :admin_dashboard).index?).to be false
      end
    end

    describe "show?" do
      it "allows admin to show dashboard" do
        expect(AdminDashboardPolicy.new(admin_adult, :admin_dashboard).show?).to be true
      end

      it "allows parent to show dashboard" do
        expect(AdminDashboardPolicy.new(parent_adult, :admin_dashboard).show?).to be true
      end

      it "allows guardian to show dashboard" do
        expect(AdminDashboardPolicy.new(guardian_adult, :admin_dashboard).show?).to be true
      end

      it "denies regular adult to show dashboard" do
        expect(AdminDashboardPolicy.new(regular_adult, :admin_dashboard).show?).to be false
      end
    end
  end

  describe "scopes" do
    let(:admin_adult) { create(:adult, family: family) }
    let(:regular_adult) { create(:adult, family: family) }
    let(:test_scope) { double("test_scope") }

    before do
      create(:adult_role, adult: admin_adult, role: admin_role)
      create(:adult_role, adult: regular_adult, role: other_role)
    end

    describe "for authorized adult" do
      it "returns the full scope" do
        expect(test_scope).to receive(:all)
        AdminDashboardPolicy::Scope.new(admin_adult, test_scope).resolve
      end
    end

    describe "for unauthorized adult" do
      it "returns empty scope" do
        expect(test_scope).to receive(:none)
        AdminDashboardPolicy::Scope.new(regular_adult, test_scope).resolve
      end
    end

    describe "for child" do
      let(:child) { create(:child, family: family) }

      it "returns empty scope" do
        expect(test_scope).to receive(:none)
        AdminDashboardPolicy::Scope.new(child, test_scope).resolve
      end
    end
  end
end