require "controllers/api/v1/test"

class Api::V1::ExperiencesControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @space = create(:space, team: @team)
    @experience = build(:experience, space: @space)
    @other_experiences = create_list(:experience, 3)

    @another_experience = create(:experience, space: @space)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @experience.save
    @another_experience.save

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
  def assert_proper_object_serialization(experience_data)
    # Fetch the experience in question and prepare to compare it's attributes.
    experience = Experience.find(experience_data["id"])

    assert_equal_or_nil experience_data["name"], experience.name
    assert_equal_or_nil experience_data["experience_type"], experience.experience_type
    assert_equal_or_nil experience_data["price_cents"], experience.price_cents
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal experience_data["space_id"], experience.space_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/spaces/#{@space.id}/experiences", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    experience_ids_returned = response.parsed_body.map { |experience| experience["id"] }
    assert_includes(experience_ids_returned, @experience.id)

    # But not returning other people's resources.
    assert_not_includes(experience_ids_returned, @other_experiences[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/experiences/#{@experience.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/experiences/#{@experience.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    experience_data = JSON.parse(build(:experience, space: nil).api_attributes.to_json)
    experience_data.except!("id", "space_id", "created_at", "updated_at")
    params[:experience] = experience_data

    post "/api/v1/spaces/#{@space.id}/experiences", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/spaces/#{@space.id}/experiences",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/experiences/#{@experience.id}", params: {
      access_token: access_token,
      experience: {
        name: "Alternative String Value",
        experience_type: "Alternative String Value",
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @experience.reload
    assert_equal @experience.name, "Alternative String Value"
    assert_equal @experience.experience_type, "Alternative String Value"
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/experiences/#{@experience.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("Experience.count", -1) do
      delete "/api/v1/experiences/#{@experience.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/experiences/#{@another_experience.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
