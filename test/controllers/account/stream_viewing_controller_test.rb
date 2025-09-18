require "test_helper"

class Account::StreamViewingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @team = create(:team)
    @user = create(:onboarded_user)
    @membership = create(:membership, user: @user, team: @team)

    @space = create(:space, team: @team, name: "Test Space")
    @experience = create(:experience, space: @space, name: "Test Experience")
    @stream = create(:stream, experience: @experience, title: "Test Stream", status: "live")

    # Create access pass and grant for the user
    @access_pass = create(:access_pass, space: @space, pricing_type: "free")
    @access_grant = create(:access_grant,
      user: @user,
      team: @team,
      purchasable: @space,
      access_pass: @access_pass,
      status: "active")

    sign_in @user
  end

  test "show renders successfully with valid access" do
    get account_viewer_stream_path(@stream)

    assert_response :success
    assert_select "h1", text: @stream.title
    assert_select "[data-controller='stream-viewer']"
  end

  test "show redirects without access" do
    @access_grant.destroy

    get account_viewer_stream_path(@stream)

    assert_redirected_to public_space_path(@space.slug)
    assert_match "Access Pass required", flash[:alert]
  end

  test "show renders error state for inaccessible stream" do
    @stream.update!(status: "scheduled", scheduled_at: 1.day.from_now)

    get account_viewer_stream_path(@stream)

    assert_response :success
    assert_select "[data-stream-viewer-target='error']"
  end

  test "video_token returns token for authorized user" do
    # Mock the LiveKit service
    mock_service = Minitest::Mock.new
    mock_connection_info = {
      room_url: "wss://test.livekit.cloud",
      access_token: "test_token",
      room_name: @stream.room_name,
      participant_identity: "user_#{@user.id}",
      can_publish: false,
      can_subscribe: true
    }

    mock_service.expect :generate_mobile_connection_info, mock_connection_info, [@stream, @user]

    Streaming::LivekitService.stub :new, mock_service do
      get video_token_account_viewer_stream_path(@stream),
        headers: {"Accept" => "application/json"}

      assert_response :success

      json_response = JSON.parse(response.body)
      assert json_response["success"]
      assert_equal "wss://test.livekit.cloud", json_response["room_url"]
      assert_equal "test_token", json_response["access_token"]
    end

    mock_service.verify
  end

  test "video_token denies access without permission" do
    @access_grant.destroy

    get video_token_account_viewer_stream_path(@stream),
      headers: {"Accept" => "application/json"}

    assert_response :forbidden

    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_match "Access Pass required", json_response["message"]
  end

  test "chat_token returns token for authorized user" do
    # Create a chat room for the stream
    create(:streaming_chat_room, stream: @stream, channel_id: "test_channel_123")

    # Mock the chat service
    mock_service = Minitest::Mock.new
    mock_service.expect :generate_user_token, "test_chat_token", [@user.id.to_s]

    Streaming::ChatService.stub :new, mock_service do
      get chat_token_account_viewer_stream_path(@stream),
        headers: {"Accept" => "application/json"}

      assert_response :success

      json_response = JSON.parse(response.body)
      assert json_response["success"]
      assert_equal "test_chat_token", json_response["token"]
      assert_equal @user.id.to_s, json_response["user_id"]
      assert_equal "test_channel_123", json_response["chat_room_id"]
    end

    mock_service.verify
  end

  test "chat_token denies access without permission" do
    @access_grant.destroy

    get chat_token_account_viewer_stream_path(@stream),
      headers: {"Accept" => "application/json"}

    assert_response :forbidden

    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_match "Access Pass required", json_response["message"]
  end

  test "stream_info returns comprehensive stream data" do
    # Mock the LiveKit service
    mock_service = Minitest::Mock.new
    mock_room_info = {name: @stream.room_name, sid: "test_sid"}
    mock_participants = [{identity: "user_1", name: "Test User"}]

    mock_service.expect :get_room_info, mock_room_info, [@stream]
    mock_service.expect :get_room_participants, mock_participants, [@stream]

    Streaming::LivekitService.stub :new, mock_service do
      get stream_info_account_viewer_stream_path(@stream),
        headers: {"Accept" => "application/json"}

      assert_response :success

      json_response = JSON.parse(response.body)
      assert json_response["success"]

      # Check stream data
      assert_equal @stream.id, json_response["stream"]["id"]
      assert_equal @stream.title, json_response["stream"]["title"]
      assert_equal @stream.status, json_response["stream"]["status"]

      # Check experience data
      assert_equal @experience.id, json_response["experience"]["id"]
      assert_equal @experience.name, json_response["experience"]["name"]

      # Check space data
      assert_equal @space.id, json_response["space"]["id"]
      assert_equal @space.name, json_response["space"]["name"]

      # Check permissions
      assert json_response["can_view"]
      assert_not json_response["can_broadcast"]

      # Check participant data
      assert_equal 1, json_response["participant_count"]
    end

    mock_service.verify
  end

  test "stream_info handles service errors gracefully" do
    # Mock the LiveKit service to raise an error
    mock_service = Minitest::Mock.new
    mock_service.expect :get_room_info, -> { raise StandardError, "Service unavailable" }, [@stream]

    Streaming::LivekitService.stub :new, mock_service do
      get stream_info_account_viewer_stream_path(@stream),
        headers: {"Accept" => "application/json"}

      assert_response :internal_server_error

      json_response = JSON.parse(response.body)
      assert_not json_response["success"]
      assert_match "Unable to get stream information", json_response["message"]
    end

    mock_service.verify
  end

  test "join_chat adds user to chat room" do
    create(:streaming_chat_room, stream: @stream, channel_id: "test_channel_123")

    # Mock the chat service methods
    mock_add_user = Minitest::Mock.new
    mock_add_user.expect :call, true, [@stream, @user]

    mock_generate_token = Minitest::Mock.new
    mock_generate_token.expect :call, "test_token", [@user, @stream]

    # Stub the controller methods
    @controller.stub :add_user_to_chat_room, mock_add_user do
      @controller.stub :generate_chat_token_for_user, mock_generate_token do
        post join_chat_account_viewer_stream_path(@stream),
          headers: {"Accept" => "application/json"}

        assert_response :success

        json_response = JSON.parse(response.body)
        assert json_response["success"]
        assert_equal "Successfully joined chat", json_response["message"]
        assert_equal "test_token", json_response["user_token"]
      end
    end
  end

  test "leave_chat removes user from chat room" do
    create(:streaming_chat_room, stream: @stream, channel_id: "test_channel_123")

    # Mock the chat service method
    mock_remove_user = Minitest::Mock.new
    mock_remove_user.expect :call, true, [@stream, @user]

    # Stub the controller method
    @controller.stub :remove_user_from_chat_room, mock_remove_user do
      delete leave_chat_account_viewer_stream_path(@stream),
        headers: {"Accept" => "application/json"}

      assert_response :success

      json_response = JSON.parse(response.body)
      assert json_response["success"]
      assert_equal "Successfully left chat", json_response["message"]
    end
  end

  test "unauthenticated user cannot access any endpoints" do
    sign_out @user

    get account_viewer_stream_path(@stream)
    assert_redirected_to new_user_session_path

    get video_token_account_viewer_stream_path(@stream)
    assert_redirected_to new_user_session_path

    get chat_token_account_viewer_stream_path(@stream)
    assert_redirected_to new_user_session_path
  end

  test "JSON requests include proper stream data structure" do
    get account_viewer_stream_path(@stream, format: :json)

    assert_response :success

    json_response = JSON.parse(response.body)

    # Verify stream data structure
    assert_includes json_response.keys, "stream"
    assert_includes json_response.keys, "experience"
    assert_includes json_response.keys, "space"
    assert_includes json_response.keys, "access_grant"
    assert_includes json_response.keys, "permissions"

    # Verify nested data
    assert_equal @stream.id, json_response["stream"]["id"]
    assert_equal @experience.id, json_response["experience"]["id"]
    assert_equal @space.id, json_response["space"]["id"]
    assert_equal @access_grant.id, json_response["access_grant"]["id"]
  end

  private

  def create(factory_name, **attributes)
    FactoryBot.create(factory_name, **attributes)
  end
end
