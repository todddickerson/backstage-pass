FactoryBot.define do
  factory :access_pass do
    association :space
    name { "Premium Access Pass" }
    description { "Get full access to all experiences" }
    pricing_type { "one_time" }
    price_cents { 9900 }
    stock_limit { 100 }
    waitlist_enabled { false }
    published { true }
    slug { name.parameterize if name.present? }
  end
end
