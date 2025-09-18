require "test_helper"

class PublicStreamingIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @creator = create(:onboarded_user, first_name: "Creator", last_name: "Test")
    @user = create(:onboarded_user, first_name: "Audience", last_name: "Member")

    @team = @creator.current_team
    @space = @team.primary_space
    @space.update!(slug: "test-space")

    # Create a live stream experience
    @experience = Experience.create!(
      space: @space,
      name: "Test Live Stream",
      description: "A test streaming experience",
      experience_type: "live_stream",
      price_cents: 0,
      slug: "test-stream"
    )

    # Create a stream for the experience
    @stream = Stream.create!(
      experience: @experience,
      title: "Test Stream",
      description: "Testing streaming functionality",
      status: "live"
    )

    # Create access grant for user
    @access_grant = @team.access_grants.create!(
      user: @user,
      purchasable: @experience,
      status: "active"
    )
  end

  test "public experience page loads correctly" do
    puts "DEBUG: Space slug: #{@space.slug}, Experience slug: #{@experience.slug}"
    puts "DEBUG: URL: /#{@space.slug}/#{@experience.slug}"
    get "/#{@space.slug}/#{@experience.slug}"
    puts "DEBUG: Response status: #{response.status}"
    assert_response :success
    assert_select "h1", @experience.name
    assert_select "#livekit-room[data-controller='streaming']"
    assert_select "[data-controller='chat']"
  end

  test "experience page shows LiveKit and GetStream scripts for live streams" do
    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_includes response.body, "livekit-client"
    assert_includes response.body, "stream-chat"
  end

  test "video token endpoint requires authentication" do
    get "/#{@space.slug}/#{@experience.slug}/video_token",
      headers: {"Accept" => "application/json"}
    assert_response :unauthorized

    response_data = JSON.parse(response.body)
    refute response_data["success"]
    assert_includes response_data["message"], "authentication required"
  end

  test "video token endpoint returns token for authorized user" do
    sign_in @user

    get "/#{@space.slug}/#{@experience.slug}/video_token",
      headers: {"Accept" => "application/json"}

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_present response_data["room_url"]
    assert_present response_data["access_token"]
    assert_present response_data["participant_identity"]
    assert_present response_data["participant_name"]
  end

  test "video token endpoint denies access without proper grants" do
    other_user = create(:onboarded_user, first_name: "Other", last_name: "User")
    sign_in other_user

    get "/#{@space.slug}/#{@experience.slug}/video_token",
      headers: {"Accept" => "application/json"}

    assert_response :forbidden
    response_data = JSON.parse(response.body)
    refute response_data["success"]
    assert_includes response_data["message"], "access denied"
  end

  test "chat token endpoint requires authentication" do
    get "/#{@space.slug}/#{@experience.slug}/chat_token",
      headers: {"Accept" => "application/json"}
    assert_response :unauthorized

    response_data = JSON.parse(response.body)
    refute response_data["success"]
    assert_includes response_data["message"], "authentication required"
  end

  test "chat token endpoint returns token for authorized user" do
    sign_in @user

    get "/#{@space.slug}/#{@experience.slug}/chat_token",
      headers: {"Accept" => "application/json"}

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_present response_data["token"]
    assert_present response_data["user_id"]
    assert_present response_data["channel_id"]
    assert_present response_data["api_key"]
  end

  test "stream info endpoint provides current stream data" do
    @stream.update!(viewer_count: 5, max_viewers: 10)

    get "/#{@space.slug}/#{@experience.slug}/stream_info",
      headers: {"Accept" => "application/json"}

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_equal 5, response_data["participant_count"]
    assert_present response_data["stream"]
    assert_equal @stream.id, response_data["stream"]["id"]
    assert_equal 10, response_data["stream"]["max_viewers"]
  end

  test "stream info endpoint works without authentication" do
    # Stream info should be publicly accessible
    get "/#{@space.slug}/#{@experience.slug}/stream_info",
      headers: {"Accept" => "application/json"}

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
  end

  test "experience page handles no active stream gracefully" do
    @stream.update!(status: "ended")

    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_select "h2", text: "No Active Streams"
    assert_select ".text-gray-600", text: /currently no live streams/
  end

  test "scheduled streams are displayed on experience page" do
    @stream.update!(status: "ended")
    scheduled_stream = @experience.streams.create!(
      title: "Upcoming Stream",
      description: "Future stream",
      status: "scheduled",
      scheduled_at: 1.hour.from_now
    )

    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_select "h3", text: "Upcoming Streams"
    assert_select ".font-medium", text: scheduled_stream.title
  end

  test "broadcaster controls appear for authorized users" do
    # Make user a space owner/manager
    @space.update!(user: @creator)
    sign_in @creator

    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_select "[data-action*='streaming#startStream'], [data-action*='streaming#stopStream']"
  end

  test "broadcaster controls hidden from regular users" do
    sign_in @user

    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    # Should not have broadcaster controls
    assert_select "[data-action*='streaming#startStream']", count: 0
    assert_select "[data-action*='streaming#stopStream']", count: 0
  end

  test "invalid space slug returns 404" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get "/nonexistent-space/#{@experience.slug}"
    end
  end

  test "invalid experience slug returns 404" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get "/#{@space.slug}/nonexistent-experience"
    end
  end

  test "reserved path slugs are properly handled" do
    # Create space with reserved path
    reserved_space = @team.spaces.create!(
      name: "Account Space",
      slug: "account"  # This should conflict with /account routes
    )

    experience = Experience.create!(
      space: reserved_space,
      name: "Test Experience",
      experience_type: "live_stream",
      price_cents: 0,
      slug: "test"
    )

    # Should not route to public controller due to reserved path constraint
    get "/account/#{experience.slug}"
    # This should either 404 or route to account controller, not public
    assert_not_includes response.body, "data-controller=\"streaming\""
  end

  test "experience data attributes are properly set for JavaScript controllers" do
    sign_in @user
    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success

    # Check streaming controller data attributes
    assert_select "#livekit-room[data-streaming-room-name='#{@stream.room_name}']"
    assert_select "#livekit-room[data-streaming-experience-slug='#{@experience.slug}']"
    assert_select "#livekit-room[data-streaming-space-slug='#{@space.slug}']"

    # Check chat controller data attributes
    assert_select "[data-controller='chat']"
    assert_select "[data-chat-experience-slug='#{@experience.slug}']"
    assert_select "[data-chat-space-slug='#{@space.slug}']"
  end

  test "non-live-streaming experience types display appropriately" do
    course_experience = @space.experiences.create!(
      name: "Course Experience",
      description: "Not a streaming experience",
      experience_type: "course",
      price_cents: 2999,
      slug: "course-test"
    )

    get "/#{@space.slug}/#{course_experience.slug}"
    assert_response :success
    assert_select "h2", text: "Course Experience"
    assert_select ".text-gray-600", text: /not currently set up for live streaming/

    # Should not have streaming-related scripts or controllers
    refute_includes response.body, "livekit-client"
    refute_includes response.body, "stream-chat"
    assert_select "[data-controller='streaming']", count: 0
  end

  test "experience pricing is displayed correctly" do
    paid_experience = @space.experiences.create!(
      name: "Paid Experience",
      description: "Premium content",
      experience_type: "live_stream",
      price_cents: 2999,
      slug: "paid-stream"
    )

    get "/#{@space.slug}/#{paid_experience.slug}"
    assert_response :success
    assert_select ".text-2xl", text: "$29.99"
  end

  test "free experience pricing is displayed correctly" do
    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_select ".text-2xl", text: "Free"
  end

  test "experience type badge is displayed with correct styling" do
    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_select ".bg-red-100.text-red-800", text: "Live stream"
  end

  test "viewer count and stream status are displayed correctly" do
    @stream.update!(viewer_count: 25)

    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_select "#participant-count", text: "0" # Default shown, updated via JS
    assert_select ".text-white", text: "LIVE"
    assert_select ".animate-ping" # Live indicator animation
  end

  test "chat interface displays correctly for authorized users" do
    sign_in @user

    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_select "h3", text: "Chat"
    assert_select "#chat-input"
    assert_select "[data-action='click->chat#sendMessage']", text: "Send"
  end

  test "chat interface shows sign-in prompt for unauthenticated users" do
    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success
    assert_select "p", text: "Join the conversation!"
    assert_select "a[href*='sign_in']", text: "Sign In"
  end

  test "multiple streams per experience show latest live stream" do
    # Create additional streams
    old_stream = @experience.streams.create!(
      title: "Old Stream",
      status: "ended",
      created_at: 2.hours.ago
    )

    current_stream = @experience.streams.create!(
      title: "Current Stream",
      status: "live",
      created_at: 1.hour.ago
    )

    get "/#{@space.slug}/#{@experience.slug}"
    assert_response :success

    # Should show the current live stream, not the old one
    assert_includes response.body, current_stream.room_name
    refute_includes response.body, old_stream.room_name
  end
end
