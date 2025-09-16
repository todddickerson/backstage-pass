FactoryBot.define do
  factory :creators_profile, class: "Creators::Profile" do
    user { nil }
    username { "MyString" }
    bio { "MyText" }
    display_name { "MyString" }
    website_url { "MyString" }
  end
end
