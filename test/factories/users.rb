FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "generic-user-#{n}@example.com" }
    # Use a strong password that passes breach validation
    password { "Test@Pass123!Secure#{rand(1000..9999)}" }
    password_confirmation { password }
    sign_in_count { 1 }
    current_sign_in_at { Time.now }
    last_sign_in_at { 1.day.ago }
    current_sign_in_ip { "127.0.0.1" }
    last_sign_in_ip { "127.0.0.2" }
    time_zone { ActiveSupport::TimeZone.all.first.name }
    locale { nil }
    factory :onboarded_user do
      first_name { "First Name" }
      last_name { "Last Name" }
      after(:create) do |user|
        user.create_default_team
      end
      factory :two_factor_user do
        otp_secret { User.generate_otp_secret }
        otp_required_for_login { true }
      end

      factory :user_example do
        id { 42 }
        first_name { "Example First Name" }
        last_name { "Example Last Name" }
        created_at { DateTime.new(2023, 1, 1) }
        updated_at { DateTime.new(2023, 1, 2) }
      end
    end
  end
end
