require "rails_helper"

RSpec.describe Role, type: :model do
  it "is valid with a name" do
    role = Role.new(name: "admin", description: "Administrator role")
    expect(role).to be_valid
  end

  it "is invalid without a name" do
    role = Role.new(description: "Administrator role")
    expect(role).to_not be_valid
  end

  it "requires unique names" do
    Role.create!(name: "admin", description: "First admin")
    duplicate_role = Role.new(name: "admin", description: "Second admin")
    expect(duplicate_role).to_not be_valid
  end
end