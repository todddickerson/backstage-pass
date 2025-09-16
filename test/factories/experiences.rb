FactoryBot.define do
  factory :experience do
    association :space
    sequence(:name) { |n| "Test Experience #{n}" }
    description { "An amazing experience for testing" }
    experience_type { "live_stream" }
    price_cents { 999 } # $9.99

    trait :course do
      experience_type { "course" }
      name { "Test Course" }
    end

    trait :community do
      experience_type { "community" }
      name { "Test Community" }
    end

    trait :free do
      price_cents { 0 }
    end
  end
end
