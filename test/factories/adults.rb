FactoryBot.define do
  factory :adult do
    first_name { "John" }
    last_name { "Doe" }
    sequence(:email) { |n| "adult#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    association :family

    trait :admin do
      after(:create) do |adult|
        admin_role = FactoryBot.create(:role, name: "admin")
        FactoryBot.create(:adult_role, adult: adult, role: admin_role)
      end
    end

    trait :parent do
      after(:create) do |adult|
        parent_role = FactoryBot.create(:role, name: "parent")
        FactoryBot.create(:adult_role, adult: adult, role: parent_role)
      end
    end

    trait :guardian do
      after(:create) do |adult|
        guardian_role = FactoryBot.create(:role, name: "guardian")
        FactoryBot.create(:adult_role, adult: adult, role: guardian_role)
      end
    end
  end
end