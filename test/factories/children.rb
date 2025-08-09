FactoryBot.define do
  factory :child do
    association :family
    first_name { "Alice" }
    birth_date { 10.years.ago.to_date }
    avatar_color { "#3B82F6" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :young do
      birth_date { 6.years.ago.to_date }
    end

    trait :teenager do
      birth_date { 14.years.ago.to_date }
    end

    factory :alice, class: "Child" do
      first_name { "Alice" }
    end

    factory :bob, class: "Child" do
      first_name { "Bob" }
      birth_date { 8.years.ago.to_date }
    end

    factory :charlie, class: "Child" do
      first_name { "Charlie" }
      birth_date { 12.years.ago.to_date }
    end
  end
end