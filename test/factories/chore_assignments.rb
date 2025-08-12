FactoryBot.define do
  factory :chore_assignment do
    association :child
    association :chore
    active { true }

    trait :inactive do
      active { false }
    end
  end
end