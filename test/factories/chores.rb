FactoryBot.define do
  factory :chore do
    association :family
    title { "Make Bed" }
    description { "Make your bed neatly with pillows arranged" }
    instructions { "Pull covers tight, fluff pillows, arrange neatly" }
    chore_type { :constant }
    difficulty { :easy }
    estimated_minutes { 5 }
    base_value { 0.50 }
    active { true }

    trait :rotational do
      chore_type { :rotational }
    end

    trait :medium_difficulty do
      difficulty { :medium }
      base_value { 0.75 }
      estimated_minutes { 15 }
    end

    trait :hard_difficulty do
      difficulty { :hard }
      base_value { 1.50 }
      estimated_minutes { 30 }
    end

    trait :age_restricted do
      min_age { 8 }
      max_age { 14 }
    end

    factory :make_bed, class: "Chore" do
      title { "Make Bed" }
    end

    factory :clean_room, class: "Chore" do
      title { "Clean Room" }
      description { "Tidy up bedroom and organize belongings" }
      difficulty { :medium }
      estimated_minutes { 20 }
      base_value { 1.00 }
    end

    factory :take_out_trash, class: "Chore" do
      title { "Take Out Trash" }
      chore_type { :rotational }
      difficulty { :easy }
    end

    factory :organize_garage, class: "Chore" do
      title { "Organize Garage" }
      chore_type { :rotational }
      difficulty { :hard }
      estimated_minutes { 60 }
      base_value { 2.00 }
      min_age { 12 }
    end
  end
end