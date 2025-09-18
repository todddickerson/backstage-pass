require "controllers/api/v1/test"

class Api::V1::AccessPassExperiencesControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @space = create(:space, team: @team)
    @access_pass = create(:access_pass, space: @space)
    @experience = create(:experience, space: @space)
    @access_pass_experience = build(:access_pass_experience, access_pass: @access_pass, experience: @experience)
    @other_access_pass_experiences = create_list(:access_pass_experience, 3)

    @another_experience = create(:experience, space: @space)
    @another_access_pass_experience = create(:access_pass_experience, access_pass: @access_pass, experience: @another_experience)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @access_pass_experience.save
    @another_access_pass_experience.save

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
  def assert_proper_object_serialization(access_pass_experience_data)
    # Fetch the access_pass_experience in question and prepare to compare it's attributes.
    access_pass_experience = AccessPassExperience.find(access_pass_experience_data["id"])

    # Compare experience ID instead of full object since API returns experience details
    if access_pass_experience_data["experience"].present?
      assert_equal access_pass_experience_data["experience"]["id"], access_pass_experience.experience.id
    end
    assert_equal_or_nil access_pass_experience_data["included"], access_pass_experience.included
    assert_equal_or_nil access_pass_experience_data["position"], access_pass_experience.position
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal access_pass_experience_data["access_pass_id"], access_pass_experience.access_pass_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/access_passes/#{@access_pass.id}/access_pass_experiences", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    access_pass_experience_ids_returned = response.parsed_body.map { |access_pass_experience| access_pass_experience["id"] }
    assert_includes(access_pass_experience_ids_returned, @access_pass_experience.id)

    # But not returning other people's resources.
    assert_not_includes(access_pass_experience_ids_returned, @other_access_pass_experiences[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/access_pass_experiences/#{@access_pass_experience.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/access_pass_experiences/#{@access_pass_experience.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    test_experience = create(:experience, space: @space)
    params[:access_pass_experience] = {
      experience_id: test_experience.id,
      included: true,
      position: 1
    }

    post "/api/v1/access_passes/#{@access_pass.id}/access_pass_experiences", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/access_passes/#{@access_pass.id}/access_pass_experiences",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/access_pass_experiences/#{@access_pass_experience.id}", params: {
      access_token: access_token,
      access_pass_experience: {
        included: false,
        position: 2
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @access_pass_experience.reload
    assert_equal false, @access_pass_experience.included
    assert_equal 2, @access_pass_experience.position
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/access_pass_experiences/#{@access_pass_experience.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("AccessPassExperience.count", -1) do
      delete "/api/v1/access_pass_experiences/#{@access_pass_experience.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/access_pass_experiences/#{@another_access_pass_experience.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
