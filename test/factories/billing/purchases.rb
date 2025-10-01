FactoryBot.define do
  factory :billing_purchase, class: "Billing::Purchase" do
    association :team
    association :user
    association :access_pass
    amount_cents { 999 }
    stripe_charge_id { nil }
    stripe_payment_intent_id { "pi_test_#{SecureRandom.hex(8)}" }
    status { "pending" }

    trait :completed do
      status { "completed" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_subscription do
      stripe_charge_id { "sub_test_#{SecureRandom.hex(8)}" }
      stripe_payment_intent_id { nil }
    end
  end
end
