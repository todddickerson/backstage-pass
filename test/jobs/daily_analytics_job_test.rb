require "test_helper"

class DailyAnalyticsJobTest < ActiveJob::TestCase
  setup do
    @team = create(:team)
    @space = create(:space, team: @team)
    @date = Date.current
  end

  test "should create team-level snapshot" do
    # Should create team snapshot + space snapshots for all spaces
    expected_count = 1 + @team.spaces.count

    assert_difference "Analytics::DailySnapshot.count", expected_count do
      DailyAnalyticsJob.perform_now(@date)
    end

    snapshot = Analytics::DailySnapshot.find_by(team: @team, space: nil, date: @date)
    assert_not_nil snapshot
    assert_equal @team, snapshot.team
    assert_nil snapshot.space
    assert_equal @date, snapshot.date
  end

  test "should create space-level snapshots" do
    # Should create team snapshot + space snapshots
    expected_count = 1 + @team.spaces.count

    assert_difference "Analytics::DailySnapshot.count", expected_count do
      DailyAnalyticsJob.perform_now(@date)
    end

    # Check space snapshot exists
    snapshot = Analytics::DailySnapshot.find_by(team: @team, space: @space, date: @date)
    assert_not_nil snapshot
    assert_equal @team, snapshot.team
    assert_equal @space, snapshot.space
    assert_equal @date, snapshot.date
  end

  test "should calculate revenue metrics" do
    DailyAnalyticsJob.perform_now(@date)

    snapshot = Analytics::DailySnapshot.find_by(team: @team, space: nil, date: @date)
    assert_not_nil snapshot.total_revenue_cents
    assert snapshot.total_revenue_cents >= 0
  end

  test "should handle teams with no spaces" do
    # Create a team with no spaces and ensure it stays empty
    empty_team = create(:team)
    empty_team.spaces.destroy_all # Ensure no spaces exist

    # Run the job
    DailyAnalyticsJob.perform_now(@date)

    # Should create team snapshot for the empty team
    snapshot = Analytics::DailySnapshot.find_by(team: empty_team, space: nil, date: @date)
    assert_not_nil snapshot
    assert_equal empty_team, snapshot.team
    assert_nil snapshot.space

    # Should not create any space snapshots for this team
    space_snapshots = Analytics::DailySnapshot.where(team: empty_team, date: @date).where.not(space: nil)
    assert_empty space_snapshots
  end

  test "should update existing snapshots" do
    # Create initial snapshot
    DailyAnalyticsJob.perform_now(@date)
    Analytics::DailySnapshot.count

    # Run again - should update, not create new
    assert_no_difference "Analytics::DailySnapshot.count" do
      DailyAnalyticsJob.perform_now(@date)
    end
  end

  test "should complete without errors" do
    # Test that the job runs successfully
    assert_nothing_raised do
      DailyAnalyticsJob.perform_now(@date)
    end

    # Verify snapshots were created
    assert Analytics::DailySnapshot.where(date: @date).any?
  end
end
