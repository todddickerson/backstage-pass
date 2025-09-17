FactoryBot.define do
  factory :access_passes_waitlist_entry, class: "AccessPasses::WaitlistEntry" do
    association :access_pass
    email { "MyString" }
    first_name { "MyString" }
    last_name { "MyString" }
    answers { "MyText" }
    status { "MyString" }
    notes { "MyText" }
    approved_at { "2025-09-16 14:58:03" }
    rejected_at { "2025-09-16 14:58:03" }
  end
end
