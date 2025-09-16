require "controllers/api/v1/test"

class Api::V1::StreamsControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @space = create(:space, team: @team)
    @experience = create(:experience, space: @space)
    @stream = build(:stream, experience: @experience)
    @other_streams = create_list(:stream, 3)

    @another_stream = create(:stream, experience: @experience)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @stream.save
    @another_stream.save

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
  def assert_proper_object_serialization(stream_data)
    # Fetch the stream in question and prepare to compare it's attributes.
    stream = Stream.find(stream_data["id"])

    assert_equal_or_nil stream_data['title'], stream.title
    assert_equal_or_nil DateTime.parse(stream_data['scheduled_at']), stream.scheduled_at
    assert_equal_or_nil stream_data['status'], stream.status
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal stream_data["experience_id"], stream.experience_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/experiences/#{@experience.id}/streams", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    stream_ids_returned = response.parsed_body.map { |stream| stream["id"] }
    assert_includes(stream_ids_returned, @stream.id)

    # But not returning other people's resources.
    assert_not_includes(stream_ids_returned, @other_streams[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/streams/#{@stream.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/streams/#{@stream.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    stream_data = JSON.parse(build(:stream, experience: nil).api_attributes.to_json)
    stream_data.except!("id", "experience_id", "created_at", "updated_at")
    params[:stream] = stream_data

    post "/api/v1/experiences/#{@experience.id}/streams", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/experiences/#{@experience.id}/streams",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/streams/#{@stream.id}", params: {
      access_token: access_token,
      stream: {
        title: 'Alternative String Value',
        status: 'Alternative String Value',
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @stream.reload
    assert_equal @stream.title, 'Alternative String Value'
    assert_equal @stream.status, 'Alternative String Value'
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/streams/#{@stream.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("Stream.count", -1) do
      delete "/api/v1/streams/#{@stream.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/streams/#{@another_stream.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
