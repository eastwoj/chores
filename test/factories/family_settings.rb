FactoryBot.define do
  factory :family_setting do
    association :family
    payout_interval_days { 7 }
    base_chore_value { 0.50 }
    auto_approve_after_hours { 48 }
    notification_settings { {} }

    trait :weekly do
      payout_interval_days { 7 }
    end

    trait :biweekly do
      payout_interval_days { 14 }
    end

    trait :monthly do
      payout_interval_days { 30 }
    end

    trait :higher_rates do
      base_chore_value { 1.00 }
    end

    factory :johnson_settings, class: "FamilySetting" do
      # Uses default values
    end
  end
end