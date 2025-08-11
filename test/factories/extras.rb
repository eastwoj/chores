FactoryBot.define do
  factory :extra do
    association :family
    title { "Wash Car" }
    description { "Wash the family car inside and out" }
    reward_amount { 5.00 }
    available_from { Date.current }
    available_until { 1.week.from_now.to_date }
    active { true }

    trait :high_value do
      reward_amount { 10.00 }
    end

    trait :seasonal do
      available_from { Date.current }
      available_until { 1.month.from_now.to_date }
    end

    trait :limited_completions do
      max_completions { 1 }
    end

    factory :wash_car, class: "Extra" do
      title { "Wash Car" }
      reward_amount { 5.00 }
    end

    factory :organize_closet, class: "Extra" do
      title { "Organize Closet" }
      description { "Sort and organize bedroom closet" }
      reward_amount { 3.00 }
    end
  end
end