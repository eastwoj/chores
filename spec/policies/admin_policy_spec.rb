require "rails_helper"

RSpec.describe AdminPolicy, type: :policy do
  subject { AdminPolicy }
  
  let(:family) { Family.create!(name: "Test Family") }
  let(:admin_role) { Role.create!(name: "admin", description: "Admin role") }
  let(:parent_role) { Role.create!(name: "parent", description: "Parent role") }
  let(:guardian_role) { Role.create!(name: "guardian", description: "Guardian role") }
  let(:other_role) { Role.create!(name: "other", description: "Other role") }

  describe "for admin adult" do
    let(:admin_adult) { Adult.create!(first_name: "Admin", last_name: "User", email: "admin@test.com", password: "password123", family: family) }
    before { AdultRole.create!(adult: admin_adult, role: admin_role) }
    
    it { is_expected.to permit(admin_adult, :admin) }
  end

  describe "for parent adult" do
    let(:parent_adult) { Adult.create!(first_name: "Parent", last_name: "User", email: "parent@test.com", password: "password123", family: family) }
    before { AdultRole.create!(adult: parent_adult, role: parent_role) }

    it { is_expected.to permit(parent_adult, :admin) }
  end

  describe "for guardian adult" do
    let(:guardian_adult) { Adult.create!(first_name: "Guardian", last_name: "User", email: "guardian@test.com", password: "password123", family: family) }
    before { AdultRole.create!(adult: guardian_adult, role: guardian_role) }

    it { is_expected.to permit(guardian_adult, :admin) }
  end

  describe "for adult without authorized roles" do
    let(:regular_adult) { Adult.create!(first_name: "Regular", last_name: "User", email: "regular@test.com", password: "password123", family: family) }
    before { AdultRole.create!(adult: regular_adult, role: other_role) }

    it { is_expected.to_not permit(regular_adult, :admin) }
  end

  describe "for adult with no roles" do
    let(:no_role_adult) { Adult.create!(first_name: "NoRole", last_name: "User", email: "norole@test.com", password: "password123", family: family) }

    it { is_expected.to_not permit(no_role_adult, :admin) }
  end

  describe "for non-adult user (child)" do
    let(:child) { Child.create!(first_name: "Test", birth_date: 10.years.ago, family: family, avatar_color: "#FF0000") }

    it { is_expected.to_not permit(child, :admin) }
  end

  describe "for nil user" do
    it { is_expected.to_not permit(nil, :admin) }
  end

  describe "permissions" do
    let(:admin_adult) { Adult.create!(first_name: "Admin", last_name: "Test", email: "admin2@test.com", password: "password123", family: family) }
    let(:parent_adult) { Adult.create!(first_name: "Parent", last_name: "Test", email: "parent2@test.com", password: "password123", family: family) }
    let(:guardian_adult) { Adult.create!(first_name: "Guardian", last_name: "Test", email: "guardian2@test.com", password: "password123", family: family) }
    let(:regular_adult) { Adult.create!(first_name: "Regular", last_name: "Test", email: "regular2@test.com", password: "password123", family: family) }

    before do
      AdultRole.create!(adult: admin_adult, role: admin_role)
      AdultRole.create!(adult: parent_adult, role: parent_role)
      AdultRole.create!(adult: guardian_adult, role: guardian_role)
      AdultRole.create!(adult: regular_adult, role: other_role)
    end

    describe "access?" do
      it "grants access to admin" do
        expect(AdminPolicy.new(admin_adult, :admin).access?).to be true
      end

      it "grants access to parent" do
        expect(AdminPolicy.new(parent_adult, :admin).access?).to be true
      end

      it "grants access to guardian" do
        expect(AdminPolicy.new(guardian_adult, :admin).access?).to be true
      end

      it "denies access to regular adult" do
        expect(AdminPolicy.new(regular_adult, :admin).access?).to be false
      end
    end

    describe "index?" do
      it "allows admin to view admin index" do
        expect(AdminPolicy.new(admin_adult, :admin).index?).to be true
      end

      it "allows parent to view admin index" do
        expect(AdminPolicy.new(parent_adult, :admin).index?).to be true
      end

      it "allows guardian to view admin index" do
        expect(AdminPolicy.new(guardian_adult, :admin).index?).to be true
      end

      it "denies regular adult to view admin index" do
        expect(AdminPolicy.new(regular_adult, :admin).index?).to be false
      end
    end

    describe "create?" do
      it "allows admin to create" do
        expect(AdminPolicy.new(admin_adult, :admin).create?).to be true
      end

      it "allows parent to create" do
        expect(AdminPolicy.new(parent_adult, :admin).create?).to be true
      end

      it "denies guardian to create" do
        expect(AdminPolicy.new(guardian_adult, :admin).create?).to be false
      end

      it "denies regular adult to create" do
        expect(AdminPolicy.new(regular_adult, :admin).create?).to be false
      end
    end

    describe "update?" do
      it "allows admin to update" do
        expect(AdminPolicy.new(admin_adult, :admin).update?).to be true
      end

      it "allows parent to update" do
        expect(AdminPolicy.new(parent_adult, :admin).update?).to be true
      end

      it "denies guardian to update" do
        expect(AdminPolicy.new(guardian_adult, :admin).update?).to be false
      end

      it "denies regular adult to update" do
        expect(AdminPolicy.new(regular_adult, :admin).update?).to be false
      end
    end

    describe "destroy?" do
      it "allows admin to destroy" do
        expect(AdminPolicy.new(admin_adult, :admin).destroy?).to be true
      end

      it "allows parent to destroy" do
        expect(AdminPolicy.new(parent_adult, :admin).destroy?).to be true
      end

      it "denies guardian to destroy" do
        expect(AdminPolicy.new(guardian_adult, :admin).destroy?).to be false
      end

      it "denies regular adult to destroy" do
        expect(AdminPolicy.new(regular_adult, :admin).destroy?).to be false
      end
    end
  end
end