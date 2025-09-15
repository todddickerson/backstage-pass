FactoryBot.define do
  factory :space do
    association :team
    sequence(:name) { |n| "Test Space #{n}" }
    description { "A test space for creators" }
    sequence(:slug) { |n| "test-space-#{n}" }
    published { true }

    trait :unpublished do
      published { false }
    end

    trait :with_experiences do
      after(:create) do |space|
        create_list(:experience, 2, space: space)
      end
    end
  end
end
