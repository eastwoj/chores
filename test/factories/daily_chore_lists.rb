FactoryBot.define do
  factory :daily_chore_list do
    association :child
    date { Date.current }
    generated_at { Time.current }

    trait :yesterday do
      date { 1.day.ago.to_date }
    end

    trait :last_week do
      date { 1.week.ago.to_date }
    end

    trait :with_chores do
      after(:create) do |list|
        create_list(:chore_completion, 3, daily_chore_list: list, child: list.child)
      end
    end

    trait :completed do
      after(:create) do |list|
        create_list(:chore_completion, 2, :completed, daily_chore_list: list, child: list.child)
      end
    end

    factory :alice_today, class: "DailyChoreList" do
      association :child, factory: :alice
      date { Date.current }
    end

    factory :bob_today, class: "DailyChoreList" do
      association :child, factory: :bob
      date { Date.current }
    end
  end
end