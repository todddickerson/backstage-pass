FactoryBot.define do
  factory :billing_purchase, class: 'Billing::Purchase' do
    association :team
    user { nil }
    access_pass { nil }
    amount_cents { 1 }
    stripe_charge_id { nil }
    stripe_payment_intent_id { nil }
    status { "MyString" }
  end
end
