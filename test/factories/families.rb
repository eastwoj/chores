FactoryBot.define do
  factory :family do
    name { "Johnson Family" }

    after(:create) do |family|
      create(:family_setting, family: family) unless family.family_setting
    end

    trait :with_children do
      after(:create) do |family|
        create_list(:child, 3, family: family)
      end
    end

    trait :with_chores do
      after(:create) do |family|
        create_list(:chore, 5, family: family)
      end
    end

    factory :family_with_children, traits: [:with_children]
    factory :family_with_chores, traits: [:with_chores]
    factory :complete_family, traits: [:with_children, :with_chores]
  end
end