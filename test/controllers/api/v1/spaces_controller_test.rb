require "controllers/api/v1/test"

class Api::V1::SpacesControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @space = build(:space, team: @team)
    @other_spaces = create_list(:space, 3)

    @another_space = create(:space, team: @team)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @space.save
    @another_space.save

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
  def assert_proper_object_serialization(space_data)
    # Fetch the space in question and prepare to compare it's attributes.
    space = Space.find(space_data["id"])

    assert_equal_or_nil space_data["name"], space.name
    assert_equal_or_nil space_data["slug"], space.slug
    assert_equal_or_nil space_data["published"], space.published
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal space_data["team_id"], space.team_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/teams/#{@team.id}/spaces", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    space_ids_returned = response.parsed_body.map { |space| space["id"] }
    assert_includes(space_ids_returned, @space.id)

    # But not returning other people's resources.
    assert_not_includes(space_ids_returned, @other_spaces[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/spaces/#{@space.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/spaces/#{@space.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    space_data = JSON.parse(build(:space, team: nil).api_attributes.to_json)
    space_data.except!("id", "team_id", "created_at", "updated_at")
    params[:space] = space_data

    post "/api/v1/teams/#{@team.id}/spaces", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/teams/#{@team.id}/spaces",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/spaces/#{@space.id}", params: {
      access_token: access_token,
      space: {
        name: "Alternative String Value",
        slug: "Alternative String Value",
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @space.reload
    assert_equal @space.name, "Alternative String Value"
    assert_equal @space.slug, "Alternative String Value"
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/spaces/#{@space.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("Space.count", -1) do
      delete "/api/v1/spaces/#{@space.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/spaces/#{@another_space.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
