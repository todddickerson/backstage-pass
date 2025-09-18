require "test_helper"

class Analytics::DailySnapshotTest < ActiveSupport::TestCase
  setup do
    @team = create(:team)
    @space = create(:space, team: @team)
    @date = Date.current
  end

  test "should create valid snapshot" do
    snapshot = Analytics::DailySnapshot.new(
      team: @team,
      space: @space,
      date: @date,
      total_revenue_cents: 5000,
      purchases_count: 3,
      active_passes_count: 10,
      stream_views: 100,
      chat_messages: 50
    )

    assert snapshot.valid?
    assert snapshot.save
  end

  test "should require team" do
    snapshot = Analytics::DailySnapshot.new(
      date: @date,
      total_revenue_cents: 1000,
      purchases_count: 1,
      active_passes_count: 1,
      stream_views: 10,
      chat_messages: 5
      # No team or space
    )

    assert_not snapshot.valid?
    assert_includes snapshot.errors[:team], "must exist"
  end

  test "should require date" do
    snapshot = Analytics::DailySnapshot.new(
      team: @team,
      space: @space
    )

    assert_not snapshot.valid?
    assert_includes snapshot.errors[:date], "can't be blank"
  end

  test "should enforce unique constraint on team, space, and date" do
    # Create first snapshot
    Analytics::DailySnapshot.create!(
      team: @team,
      space: @space,
      date: @date,
      total_revenue_cents: 1000,
      purchases_count: 1,
      active_passes_count: 1,
      stream_views: 10,
      chat_messages: 5
    )

    # Attempt to create duplicate
    duplicate = Analytics::DailySnapshot.new(
      team: @team,
      space: @space,
      date: @date,
      total_revenue_cents: 2000,
      purchases_count: 2,
      active_passes_count: 2,
      stream_views: 20,
      chat_messages: 10
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:date], "has already been taken"
  end

  test "should require numeric fields" do
    snapshot = Analytics::DailySnapshot.new(
      team: @team,
      date: @date
      # Missing required numeric fields
    )

    assert_not snapshot.valid?
    assert_includes snapshot.errors[:total_revenue_cents], "can't be blank"
    assert_includes snapshot.errors[:purchases_count], "can't be blank"
    assert_includes snapshot.errors[:active_passes_count], "can't be blank"
    assert_includes snapshot.errors[:stream_views], "can't be blank"
    assert_includes snapshot.errors[:chat_messages], "can't be blank"
  end

  test "should format revenue display correctly" do
    snapshot = Analytics::DailySnapshot.new(
      team: @team,
      date: @date,
      total_revenue_cents: 12345
    )

    assert_equal "$123.45", snapshot.revenue_display
  end

  test "should handle zero revenue display" do
    snapshot = Analytics::DailySnapshot.new(
      team: @team,
      date: @date,
      total_revenue_cents: 0
    )

    assert_equal "$0.0", snapshot.revenue_display
  end

  test "should calculate engagement rate" do
    snapshot = Analytics::DailySnapshot.new(
      team: @team,
      date: @date,
      stream_views: 100,
      chat_messages: 25
    )

    assert_equal 25.0, snapshot.engagement_rate
  end

  test "should handle zero engagement rate when no views" do
    snapshot = Analytics::DailySnapshot.new(
      team: @team,
      date: @date,
      stream_views: 0,
      chat_messages: 10
    )

    assert_equal 0.0, snapshot.engagement_rate
  end

  test "for_space scope should filter by space" do
    space2 = create(:space, team: @team)

    # Create snapshots for different spaces
    snapshot1 = Analytics::DailySnapshot.create!(
      team: @team,
      space: @space,
      date: @date,
      total_revenue_cents: 1000,
      purchases_count: 1,
      active_passes_count: 1,
      stream_views: 10,
      chat_messages: 5
    )

    snapshot2 = Analytics::DailySnapshot.create!(
      team: @team,
      space: space2,
      date: @date,
      total_revenue_cents: 2000,
      purchases_count: 2,
      active_passes_count: 2,
      stream_views: 20,
      chat_messages: 10
    )

    space_snapshots = Analytics::DailySnapshot.for_space(@space)
    assert_includes space_snapshots, snapshot1
    assert_not_includes space_snapshots, snapshot2
  end

  test "for_date_range scope should filter by date range" do
    # Create snapshots for different dates
    old_snapshot = Analytics::DailySnapshot.create!(
      team: @team,
      space: @space,
      date: 10.days.ago,
      total_revenue_cents: 1000,
      purchases_count: 1,
      active_passes_count: 1,
      stream_views: 10,
      chat_messages: 5
    )

    recent_snapshot = Analytics::DailySnapshot.create!(
      team: @team,
      space: @space,
      date: @date,
      total_revenue_cents: 2000,
      purchases_count: 2,
      active_passes_count: 2,
      stream_views: 20,
      chat_messages: 10
    )

    range_snapshots = Analytics::DailySnapshot.for_date_range(5.days.ago, Date.current)
    assert_includes range_snapshots, recent_snapshot
    assert_not_includes range_snapshots, old_snapshot
  end

  test "by_date scope should order by date ascending" do
    # Create snapshots in random order
    snapshot2 = Analytics::DailySnapshot.create!(
      team: @team,
      date: @date + 1.day,
      total_revenue_cents: 2000,
      purchases_count: 2,
      active_passes_count: 2,
      stream_views: 20,
      chat_messages: 10
    )

    snapshot1 = Analytics::DailySnapshot.create!(
      team: @team,
      date: @date,
      total_revenue_cents: 1000,
      purchases_count: 1,
      active_passes_count: 1,
      stream_views: 10,
      chat_messages: 5
    )

    ordered_snapshots = Analytics::DailySnapshot.by_date
    assert_equal snapshot1, ordered_snapshots.first
    assert_equal snapshot2, ordered_snapshots.last
  end

  test "should allow team-level snapshots without space" do
    snapshot = Analytics::DailySnapshot.create!(
      team: @team,
      space: nil,
      date: @date,
      total_revenue_cents: 10000,
      purchases_count: 5,
      active_passes_count: 15,
      stream_views: 100,
      chat_messages: 50
    )

    assert_nil snapshot.space
    assert_equal @team, snapshot.team
  end
end
