FactoryBot.define do
  factory :chore_list do
    association :child
    interval { :daily }
    start_date { Date.current }
    generated_at { Time.current }

    trait :weekly do
      interval { :weekly }
    end

    trait :monthly do
      interval { :monthly }
    end

    trait :with_chores do
      after(:create) do |list|
        create_list(:chore_completion, 3, chore_list: list, child: list.child)
      end
    end

    trait :completed do
      after(:create) do |list|
        create_list(:chore_completion, 2, :completed, chore_list: list, child: list.child)
      end
    end
  end
end