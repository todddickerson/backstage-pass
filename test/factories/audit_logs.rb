FactoryBot.define do
  factory :audit_log do
    association :user
    action { "user_login" }
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" }
    params { {} }
    performed_at { Time.current }
    
    trait :without_user do
      user { nil }
    end
    
    trait :sensitive_action do
      action { "password_reset" }
      params { {email: "user@example.com"} }
    end
  end
end
