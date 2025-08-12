FactoryBot.define do
  factory :adult_role do
    association :adult
    association :role
  end
end
