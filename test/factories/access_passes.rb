FactoryBot.define do
  factory :access_pass do
    user
    team
    association :purchasable, factory: :space
    status { 'active' }
    expires_at { 1.month.from_now }

    # Ensure team relationship is consistent
    after(:build) do |access_pass|
      if access_pass.purchasable.respond_to?(:team)
        access_pass.team = access_pass.purchasable.team
      end
    end

    trait :expired do
      status { 'expired' }
      expires_at { 1.week.ago }
    end

    trait :for_space do
      association :purchasable, factory: :space
    end

    trait :for_experience do
      association :purchasable, factory: :experience
    end
  end
end
