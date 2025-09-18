FactoryBot.define do
  factory :access_grant do
    team
    user
    access_pass
    status { "active" }
    expires_at { nil } # Lifetime access by default

    # Default to space-level access
    association :purchasable, factory: :space

    trait :space_access do
      association :purchasable, factory: :space
    end

    trait :experience_access do
      association :purchasable, factory: :experience
    end

    trait :expired do
      status { "expired" }
      expires_at { 1.hour.ago }
    end

    trait :with_expiration do
      expires_at { 30.days.from_now }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :refunded do
      status { "refunded" }
    end

    # Ensure consistent team relationships
    after(:build) do |access_grant|
      # If purchasable is set, use its team
      if access_grant.purchasable&.respond_to?(:team)
        access_grant.team = access_grant.purchasable.team
      elsif access_grant.purchasable&.respond_to?(:space) && access_grant.purchasable.space&.team
        access_grant.team = access_grant.purchasable.space.team
      end

      # Ensure access_pass matches the purchasable if not explicitly set
      if access_grant.access_pass && access_grant.purchasable
        # Only update if the access_pass doesn't match the purchasable
        case access_grant.purchasable_type
        when "Space"
          unless access_grant.access_pass.space == access_grant.purchasable
            access_grant.access_pass = create(:access_pass, space: access_grant.purchasable)
          end
        when "Experience"
          # For experience-level access, the access_pass should be associated with the experience's space
          unless access_grant.access_pass.space == access_grant.purchasable.space
            access_grant.access_pass = create(:access_pass, space: access_grant.purchasable.space)
          end
        end
      end
    end
  end
end
