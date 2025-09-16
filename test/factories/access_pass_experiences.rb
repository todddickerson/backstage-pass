FactoryBot.define do
  factory :access_pass_experience do
    association :access_pass
    association :experience
    included { true }
    position { 1 }
  end
end
