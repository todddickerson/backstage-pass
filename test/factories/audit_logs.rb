FactoryBot.define do
  factory :audit_log do
    user { nil }
    action { "MyString" }
    ip_address { "MyString" }
    user_agent { "MyText" }
    params { "" }
    performed_at { "2025-09-17 12:18:02" }
  end
end
