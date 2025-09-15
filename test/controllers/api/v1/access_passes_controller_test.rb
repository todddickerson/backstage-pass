require "controllers/api/v1/test"

class Api::V1::AccessPassesControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @access_pass = build(:access_pass, team: @team)
    @other_access_passes = create_list(:access_pass, 3)

    @another_access_pass = create(:access_pass, team: @team)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @access_pass.save
    @another_access_pass.save

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
  def assert_proper_object_serialization(access_pass_data)
    # Fetch the access_pass in question and prepare to compare it's attributes.
    access_pass = AccessPass.find(access_pass_data["id"])

    assert_equal_or_nil access_pass_data['status'], access_pass.status
    assert_equal_or_nil DateTime.parse(access_pass_data['expires_at']), access_pass.expires_at
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal access_pass_data["team_id"], access_pass.team_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/teams/#{@team.id}/access_passes", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    access_pass_ids_returned = response.parsed_body.map { |access_pass| access_pass["id"] }
    assert_includes(access_pass_ids_returned, @access_pass.id)

    # But not returning other people's resources.
    assert_not_includes(access_pass_ids_returned, @other_access_passes[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/access_passes/#{@access_pass.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/access_passes/#{@access_pass.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    access_pass_data = JSON.parse(build(:access_pass, team: nil).api_attributes.to_json)
    access_pass_data.except!("id", "team_id", "created_at", "updated_at")
    params[:access_pass] = access_pass_data

    post "/api/v1/teams/#{@team.id}/access_passes", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/teams/#{@team.id}/access_passes",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/access_passes/#{@access_pass.id}", params: {
      access_token: access_token,
      access_pass: {
        status: 'Alternative String Value',
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @access_pass.reload
    assert_equal @access_pass.status, 'Alternative String Value'
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/access_passes/#{@access_pass.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("AccessPass.count", -1) do
      delete "/api/v1/access_passes/#{@access_pass.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/access_passes/#{@another_access_pass.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
