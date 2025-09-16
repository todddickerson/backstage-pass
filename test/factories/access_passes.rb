FactoryBot.define do
  factory :access_pass do
    association :space
    name { "MyString" }
    description { "MyText" }
    pricing_type { "MyString" }
    price_cents { 1 }
    stock_limit { 1 }
    waitlist_enabled { false }
    published { false }
  end
end
