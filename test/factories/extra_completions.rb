FactoryBot.define do
  factory :extra_completion do
    association :child
    association :extra
    status { :pending }
    earned_amount { 0.0 }

    trait :completed do
      status { :completed }
      completed_at { Time.current }
    end

    trait :approved do
      status { :approved }
      completed_at { 1.day.ago }
      approved_at { Time.current }
      earned_amount { 5.00 }
    end

    trait :rejected do
      status { :rejected }
      completed_at { 1.day.ago }
      approved_at { Time.current }
      notes { "Not completed to standard" }
      earned_amount { 0.0 }
    end

    factory :alice_wash_car, class: "ExtraCompletion" do
      association :child, factory: :alice
    end
  end
end