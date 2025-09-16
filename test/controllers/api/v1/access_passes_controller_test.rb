require "controllers/api/v1/test"

class Api::V1::AccessPassesControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @space = create(:space, team: @team)
    @access_pass = build(:access_pass, space: @space, name: "Test Access Pass")
    @other_access_passes = create_list(:access_pass, 3)

    @another_access_pass = create(:access_pass, space: @space, name: "Another Test Access Pass")

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

    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal access_pass_data["space_id"], access_pass.space_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/spaces/#{@space.id}/access_passes", params: {access_token: access_token}
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
    # Use proper factory attributes for creating
    params = {access_token: access_token}
    access_pass_data = {
      name: "New Test Access Pass",
      description: "A test access pass for creation",
      pricing_type: "one_time",
      price_cents: 1999,
      published: true
    }
    params[:access_pass] = access_pass_data

    post "/api/v1/spaces/#{@space.id}/access_passes", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/spaces/#{@space.id}/access_passes",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/access_passes/#{@access_pass.id}", params: {
      access_token: access_token,
      access_pass: {
        name: "Updated Test Access Pass"
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @access_pass.reload
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
