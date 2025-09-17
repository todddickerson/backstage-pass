FactoryBot.define do
  factory :stream do
    association :experience
    title { "Test Stream" }
    description { "A test streaming session" }
    scheduled_at { 1.hour.from_now }
    status { "scheduled" }
    
    trait :live do
      status { "live" }
      scheduled_at { 5.minutes.ago }
    end
    
    trait :ended do
      status { "ended" }
      scheduled_at { 2.hours.ago }
    end
  end
end
