require "controllers/api/v1/test"

class Api::V1::Streaming::ChatRoomsControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @space = create(:space, team: @team)
    @experience = create(:experience, space: @space)
    @stream = create(:stream, experience: @experience)
    @chat_room = build(:streaming_chat_room, stream: @stream)
    @other_chat_rooms = create_list(:streaming_chat_room, 3)

    @another_chat_room = create(:streaming_chat_room, stream: @stream)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @chat_room.save
    @another_chat_room.save

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
  def assert_proper_object_serialization(chat_room_data)
    # Fetch the chat_room in question and prepare to compare it's attributes.
    chat_room = Streaming::ChatRoom.find(chat_room_data["id"])

    assert_equal_or_nil chat_room_data["stream_id"], chat_room.stream_id
    assert_equal_or_nil chat_room_data["channel_id"], chat_room.channel_id
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal chat_room_data["stream_id"], chat_room.stream_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/streams/#{@stream.id}/streaming/chat_rooms", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    chat_room_ids_returned = response.parsed_body.map { |chat_room| chat_room["id"] }
    assert_includes(chat_room_ids_returned, @chat_room.id)

    # But not returning other people's resources.
    assert_not_includes(chat_room_ids_returned, @other_chat_rooms[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/streaming/chat_rooms/#{@chat_room.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/streaming/chat_rooms/#{@chat_room.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    chat_room_data = JSON.parse(build(:streaming_chat_room, stream: nil).api_attributes.to_json)
    chat_room_data.except!("id", "stream_id", "created_at", "updated_at")
    params[:streaming_chat_room] = chat_room_data

    post "/api/v1/streams/#{@stream.id}/streaming/chat_rooms", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/streams/#{@stream.id}/streaming/chat_rooms",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/streaming/chat_rooms/#{@chat_room.id}", params: {
      access_token: access_token,
      streaming_chat_room: {
        stream_id: "Alternative String Value",
        channel_id: "Alternative String Value",
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @chat_room.reload
    assert_equal @chat_room.stream_id, "Alternative String Value"
    assert_equal @chat_room.channel_id, "Alternative String Value"
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/streaming/chat_rooms/#{@chat_room.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("Streaming::ChatRoom.count", -1) do
      delete "/api/v1/streaming/chat_rooms/#{@chat_room.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/streaming/chat_rooms/#{@another_chat_room.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
