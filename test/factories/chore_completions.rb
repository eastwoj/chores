FactoryBot.define do
  factory :chore_completion do
    association :chore_list
    association :chore
    association :child
    status { :pending }
    earned_amount { 0.50 }

    trait :completed do
      status { :completed }
      completed_at { Time.current }
    end

    trait :reviewed_satisfactory do
      status { :reviewed_satisfactory }
      completed_at { 1.day.ago }
      reviewed_at { Time.current }
      earned_amount { 0.50 }
    end

    trait :reviewed_unsatisfactory do
      status { :reviewed_unsatisfactory }
      completed_at { 1.day.ago }
      reviewed_at { Time.current }
      review_notes { "Needs to be redone properly" }
      earned_amount { 0.0 }
    end

    factory :alice_make_bed_today, class: "ChoreCompletion" do
      association :child, factory: :alice
      association :chore, factory: :make_bed
      association :daily_chore_list, factory: :alice_today
    end

    factory :alice_make_bed_last_month, class: "ChoreCompletion" do
      association :child, factory: :alice
      association :chore, factory: :make_bed
      created_at { 32.days.ago }
    end

    factory :alice_clean_room_bad, class: "ChoreCompletion" do
      association :child, factory: :alice
      association :chore, factory: :clean_room
      status { :reviewed_unsatisfactory }
    end
  end
end