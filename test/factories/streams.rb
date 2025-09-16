FactoryBot.define do
  factory :stream do
    association :experience
    title { "MyString" }
    description { "MyText" }
    scheduled_at { "2025-09-16 13:22:43" }
    status { "MyString" }
  end
end
