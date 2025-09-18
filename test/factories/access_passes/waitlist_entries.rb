FactoryBot.define do
  factory :access_passes_waitlist_entry, class: "AccessPasses::WaitlistEntry" do
    association :access_pass
    email { "test@example.com" }
    first_name { "John" }
    last_name { "Doe" }
    answers { "MyText" }
    status { "pending" }
    notes { "MyText" }
    approved_at { "2025-09-16 14:58:03" }
    rejected_at { "2025-09-16 14:58:03" }
  end
end
