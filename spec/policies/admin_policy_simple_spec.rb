require "rails_helper"

RSpec.describe AdminPolicy, type: :policy do
  let(:family) { Family.create!(name: "Test Family") }
  let(:admin_role) { Role.create!(name: "admin", description: "Admin role") }
  let(:parent_role) { Role.create!(name: "parent", description: "Parent role") }
  let(:guardian_role) { Role.create!(name: "guardian", description: "Guardian role") }
  let(:other_role) { Role.create!(name: "other", description: "Other role") }

  describe "access permissions" do
    context "admin adult" do
      let(:admin_adult) { Adult.create!(first_name: "Admin", last_name: "User", email: "admin@test.com", password: "password123", family: family) }
      before { AdultRole.create!(adult: admin_adult, role: admin_role) }

      it "allows access" do
        policy = AdminPolicy.new(admin_adult, :admin)
        expect(policy.access?).to be true
      end

      it "allows index" do
        policy = AdminPolicy.new(admin_adult, :admin)
        expect(policy.index?).to be true
      end

      it "allows create" do
        policy = AdminPolicy.new(admin_adult, :admin)
        expect(policy.create?).to be true
      end

      it "allows update" do
        policy = AdminPolicy.new(admin_adult, :admin)
        expect(policy.update?).to be true
      end

      it "allows destroy" do
        policy = AdminPolicy.new(admin_adult, :admin)
        expect(policy.destroy?).to be true
      end
    end

    context "parent adult" do
      let(:parent_adult) { Adult.create!(first_name: "Parent", last_name: "User", email: "parent@test.com", password: "password123", family: family) }
      before { AdultRole.create!(adult: parent_adult, role: parent_role) }

      it "allows access" do
        policy = AdminPolicy.new(parent_adult, :admin)
        expect(policy.access?).to be true
      end

      it "allows create" do
        policy = AdminPolicy.new(parent_adult, :admin)
        expect(policy.create?).to be true
      end
    end

    context "guardian adult" do
      let(:guardian_adult) { Adult.create!(first_name: "Guardian", last_name: "User", email: "guardian@test.com", password: "password123", family: family) }
      before { AdultRole.create!(adult: guardian_adult, role: guardian_role) }

      it "allows access" do
        policy = AdminPolicy.new(guardian_adult, :admin)
        expect(policy.access?).to be true
      end

      it "denies create" do
        policy = AdminPolicy.new(guardian_adult, :admin)
        expect(policy.create?).to be false
      end

      it "denies update" do
        policy = AdminPolicy.new(guardian_adult, :admin)
        expect(policy.update?).to be false
      end

      it "denies destroy" do
        policy = AdminPolicy.new(guardian_adult, :admin)
        expect(policy.destroy?).to be false
      end
    end

    context "adult without authorized roles" do
      let(:regular_adult) { Adult.create!(first_name: "Regular", last_name: "User", email: "regular@test.com", password: "password123", family: family) }
      before { AdultRole.create!(adult: regular_adult, role: other_role) }

      it "denies access" do
        policy = AdminPolicy.new(regular_adult, :admin)
        expect(policy.access?).to be false
      end

      it "denies all actions" do
        policy = AdminPolicy.new(regular_adult, :admin)
        expect(policy.index?).to be false
        expect(policy.create?).to be false
        expect(policy.update?).to be false
        expect(policy.destroy?).to be false
      end
    end

    context "adult with no roles" do
      let(:no_role_adult) { Adult.create!(first_name: "NoRole", last_name: "User", email: "norole@test.com", password: "password123", family: family) }

      it "denies access" do
        policy = AdminPolicy.new(no_role_adult, :admin)
        expect(policy.access?).to be false
      end
    end

    context "non-adult user (child)" do
      let(:child) { Child.create!(first_name: "Test", birth_date: 10.years.ago, family: family, avatar_color: "#FF0000") }

      it "denies access" do
        policy = AdminPolicy.new(child, :admin)
        expect(policy.access?).to be false
      end
    end

    context "nil user" do
      it "denies access" do
        policy = AdminPolicy.new(nil, :admin)
        expect(policy.access?).to be false
      end
    end
  end

  describe "scope" do
    let(:admin_adult) { Adult.create!(first_name: "Admin", last_name: "User", email: "admin@test.com", password: "password123", family: family) }
    let(:regular_adult) { Adult.create!(first_name: "Regular", last_name: "User", email: "regular@test.com", password: "password123", family: family) }
    let(:test_scope) { double("test_scope") }

    before do
      AdultRole.create!(adult: admin_adult, role: admin_role)
      AdultRole.create!(adult: regular_adult, role: other_role)
    end

    it "returns full scope for authorized admin" do
      expect(test_scope).to receive(:all)
      AdminPolicy::Scope.new(admin_adult, test_scope).resolve
    end

    it "returns empty scope for unauthorized adult" do
      expect(test_scope).to receive(:none)
      AdminPolicy::Scope.new(regular_adult, test_scope).resolve
    end
  end
end