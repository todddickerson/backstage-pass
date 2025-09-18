FactoryBot.define do
  factory :analytics_daily_snapshot, class: "Analytics::DailySnapshot" do
    association :team
    date { "2025-09-18" }
    space { nil }
    total_revenue_cents { 1 }
    purchases_count { 1 }
    active_passes_count { 1 }
    stream_views { 1 }
    chat_messages { 1 }
  end
end
