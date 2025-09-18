require "controllers/api/v1/test"

class Api::V1::Analytics::DailySnapshotsControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @daily_snapshot = build(:analytics_daily_snapshot, team: @team)
    @other_daily_snapshots = create_list(:analytics_daily_snapshot, 3)

    @another_daily_snapshot = create(:analytics_daily_snapshot, team: @team)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @daily_snapshot.save
    @another_daily_snapshot.save

    @original_hide_things = ENV["HIDE_THINGS"]
    ENV["HIDE_THINGS"] = "false"
    Rails.application.reload_routes!
  end

  teardown do
    ENV["HIDE_THINGS"] = @original_hide_things
    Rails.application.reload_routes!
  end

  # This assertion is written in such a way that new attributes won't cause the tests to start failing, but removing
  # data we were previously providing to users _will_ break the test suite.
  def assert_proper_object_serialization(daily_snapshot_data)
    # Fetch the daily_snapshot in question and prepare to compare it's attributes.
    daily_snapshot = Analytics::DailySnapshot.find(daily_snapshot_data["id"])

    assert_equal_or_nil Date.parse(daily_snapshot_data["date"]), daily_snapshot.date
    assert_equal_or_nil daily_snapshot_data["space_id"], daily_snapshot.space_id
    assert_equal_or_nil daily_snapshot_data["total_revenue_cents"], daily_snapshot.total_revenue_cents
    assert_equal_or_nil daily_snapshot_data["purchases_count"], daily_snapshot.purchases_count
    assert_equal_or_nil daily_snapshot_data["active_passes_count"], daily_snapshot.active_passes_count
    assert_equal_or_nil daily_snapshot_data["stream_views"], daily_snapshot.stream_views
    assert_equal_or_nil daily_snapshot_data["chat_messages"], daily_snapshot.chat_messages
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal daily_snapshot_data["team_id"], daily_snapshot.team_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/teams/#{@team.id}/analytics/daily_snapshots", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    daily_snapshot_ids_returned = response.parsed_body.map { |daily_snapshot| daily_snapshot["id"] }
    assert_includes(daily_snapshot_ids_returned, @daily_snapshot.id)

    # But not returning other people's resources.
    assert_not_includes(daily_snapshot_ids_returned, @other_daily_snapshots[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/analytics/daily_snapshots/#{@daily_snapshot.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/analytics/daily_snapshots/#{@daily_snapshot.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    daily_snapshot_data = JSON.parse(build(:analytics_daily_snapshot, team: nil).api_attributes.to_json)
    daily_snapshot_data.except!("id", "team_id", "created_at", "updated_at")
    params[:analytics_daily_snapshot] = daily_snapshot_data

    post "/api/v1/teams/#{@team.id}/analytics/daily_snapshots", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/teams/#{@team.id}/analytics/daily_snapshots",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/analytics/daily_snapshots/#{@daily_snapshot.id}", params: {
      access_token: access_token,
      analytics_daily_snapshot: {
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @daily_snapshot.reload
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/analytics/daily_snapshots/#{@daily_snapshot.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("Analytics::DailySnapshot.count", -1) do
      delete "/api/v1/analytics/daily_snapshots/#{@daily_snapshot.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/analytics/daily_snapshots/#{@another_daily_snapshot.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
