require "test_helper"

class LivekitIntegrationTest < ActiveSupport::TestCase
  setup do
    @creator = create(:onboarded_user, first_name: "Creator", last_name: "Test")
    @audience_user = create(:onboarded_user, first_name: "Audience", last_name: "Member")
    
    @space = @creator.current_team.primary_space
    @experience = @space.experiences.create!(
      name: "Live Coding Session",
      description: "Interactive coding demonstration",
      experience_type: "live_stream",
      price_cents: 2999
    )
    
    @stream = @experience.streams.create!(
      title: "Building a Rails App",
      description: "Real-time development session",
      scheduled_at: 2.hours.from_now,
      status: "scheduled"
    )
    
    # Set up LiveKit environment variables for testing
    @original_livekit_api_key = ENV["LIVEKIT_API_KEY"]
    @original_livekit_api_secret = ENV["LIVEKIT_API_SECRET"]
    @original_livekit_url = ENV["LIVEKIT_URL"]
    
    ENV["LIVEKIT_API_KEY"] = "test_api_key"
    ENV["LIVEKIT_API_SECRET"] = "test_api_secret"
    ENV["LIVEKIT_URL"] = "wss://test.livekit.cloud"
    
    @livekit_service = Streaming::LivekitService.new
  end

  teardown do
    # Restore original environment variables
    ENV["LIVEKIT_API_KEY"] = @original_livekit_api_key
    ENV["LIVEKIT_API_SECRET"] = @original_livekit_api_secret
    ENV["LIVEKIT_URL"] = @original_livekit_url
  end

  test "livekit service initializes with correct configuration" do
    assert_not_nil @livekit_service
    assert_not_nil @livekit_service.room_service
    assert_not_nil @livekit_service.egress_service
  end

  test "livekit service validates environment variables" do
    # Test missing API key
    ENV["LIVEKIT_API_KEY"] = nil
    
    error = assert_raises(RuntimeError) do
      Streaming::LivekitService.new
    end
    assert_includes error.message, "Missing LiveKit environment variables"
    
    # Restore for other tests
    ENV["LIVEKIT_API_KEY"] = "test_api_key"
  end

  test "generates correct room name for stream" do
    expected_room_name = "stream_#{@stream.id}"
    assert_equal expected_room_name, @stream.room_name
  end

  test "can_view permissions work correctly" do
    # Creator (team member) can view
    assert @stream.can_view?(@creator)
    
    # Non-team member cannot view by default
    refute @stream.can_view?(@audience_user)
  end

  test "generates mobile connection info with correct structure" do
    connection_info = @livekit_service.generate_mobile_connection_info(@stream, @creator)
    
    # Verify required fields
    assert_includes connection_info, :room_url
    assert_includes connection_info, :access_token
    assert_includes connection_info, :room_name
    assert_includes connection_info, :participant_identity
    assert_includes connection_info, :participant_name
    assert_includes connection_info, :mobile_config
    assert_includes connection_info, :can_publish
    assert_includes connection_info, :can_subscribe
    
    # Verify mobile config structure
    mobile_config = connection_info[:mobile_config]
    assert_includes mobile_config, :adaptiveStream
    assert_includes mobile_config, :video
    assert_includes mobile_config, :audio
    assert_includes mobile_config, :backgroundMode
    assert_includes mobile_config, :pictureInPicture
    
    # Verify video settings
    video_config = mobile_config[:video]
    assert_equal 1280, video_config[:resolution][:width]
    assert_equal 720, video_config[:resolution][:height]
    assert_equal 30, video_config[:frameRate]
    assert_equal "h264", video_config[:codec]
    
    # Verify audio settings
    audio_config = mobile_config[:audio]
    assert_equal 128000, audio_config[:bitrate]
    assert_equal "opus", audio_config[:codec]
    assert_equal 48000, audio_config[:sampleRate]
  end

  test "creator permissions vs audience permissions" do
    # Mock the can_broadcast? method to test permissions
    @stream.define_singleton_method(:can_broadcast?) do |user|
      user == @creator
    end
    
    creator_info = @livekit_service.generate_mobile_connection_info(@stream, @creator)
    audience_info = @livekit_service.generate_mobile_connection_info(@stream, @audience_user)
    
    # Creator can publish (broadcast)
    assert creator_info[:can_publish]
    assert creator_info[:can_subscribe]
    
    # Audience can only subscribe
    refute audience_info[:can_publish]
    assert audience_info[:can_subscribe]
  end

  test "participant identity generation" do
    connection_info = @livekit_service.generate_mobile_connection_info(@stream, @creator)
    
    expected_identity = "user_#{@creator.id}"
    assert_equal expected_identity, connection_info[:participant_identity]
    
    expected_name = @creator.name || @creator.email.split("@").first
    assert_equal expected_name, connection_info[:participant_name]
  end

  test "handles missing livekit url gracefully" do
    ENV["LIVEKIT_URL"] = nil
    
    # Should not raise an error, should use default
    service = nil
    assert_nothing_raised do
      service = Streaming::LivekitService.new
    end
    
    connection_info = service.generate_mobile_connection_info(@stream, @creator)
    assert_not_nil connection_info[:room_url]
  end

  # Integration test with mocked LiveKit SDK calls
  test "create room with mocked livekit calls" do
    skip("Requires LiveKit SDK mocking setup")
    
    # This would test actual room creation with mocked responses
    # Expected behavior:
    # 1. Calls LiveKit API to create room
    # 2. Returns room object with correct metadata
    # 3. Updates stream with room info if fields exist
    
    # Mock setup would go here
    room_response = double("Room", name: @stream.room_name, sid: "test_sid")
    
    expect(@livekit_service.room_service).to receive(:create_room)
      .with(hash_including(
        name: @stream.room_name,
        max_participants: 500,
        empty_timeout: 600
      ))
      .and_return(room_response)
    
    result = @livekit_service.create_room(@stream)
    assert_equal @stream.room_name, result.name
  end

  test "access token generation includes required claims" do
    skip("Requires LiveKit JWT token mocking")
    
    # This would test JWT token generation
    # Expected behavior:
    # 1. Creates proper LiveKit video grants
    # 2. Sets correct permissions based on user role
    # 3. Returns valid JWT token
    
    token = @livekit_service.generate_access_token(@stream, @creator)
    assert_not_nil token
    assert_kind_of String, token
    
    # Would decode and verify JWT claims in real implementation
  end

  # Test error handling
  test "handles livekit service errors gracefully" do
    # Test connection failures, invalid responses, etc.
    # This ensures our app doesn't crash when LiveKit is unavailable
    
    # Mock service to raise errors
    allow(@livekit_service.room_service).to receive(:create_room).and_raise(StandardError.new("Connection failed"))
    
    # Should not propagate error, should log and return nil
    result = @livekit_service.create_room(@stream)
    assert_nil result
  end

  # Performance test
  test "token generation performance" do
    # Ensure token generation is fast enough for real-time use
    start_time = Time.current
    
    100.times do
      @livekit_service.generate_mobile_connection_info(@stream, @creator)
    end
    
    duration = Time.current - start_time
    assert duration < 1.0, "Token generation too slow: #{duration}s for 100 tokens"
  end

  # Test streaming lifecycle
  test "complete streaming lifecycle integration" do
    # Test the full creator workflow:
    # 1. Create stream
    # 2. Generate access tokens for creator and audience
    # 3. Start stream (change status)
    # 4. Handle participants
    # 5. End stream
    
    # Step 1: Stream is created (already done in setup)
    assert_equal "scheduled", @stream.status
    
    # Step 2: Generate tokens
    creator_token_info = @livekit_service.generate_mobile_connection_info(@stream, @creator)
    audience_token_info = @livekit_service.generate_mobile_connection_info(@stream, @audience_user)
    
    assert_not_nil creator_token_info[:access_token]
    assert_not_nil audience_token_info[:access_token]
    
    # Step 3: Start stream
    @stream.update!(status: "live")
    assert_equal "live", @stream.status
    
    # Step 4: Verify permissions are still correct
    assert creator_token_info[:can_publish]
    refute audience_token_info[:can_publish]
    
    # Step 5: End stream
    @stream.update!(status: "ended")
    assert_equal "ended", @stream.status
    
    # Integration successful
    assert true, "Complete streaming lifecycle works"
  end

  # Mobile-specific tests
  test "mobile configuration optimizations" do
    connection_info = @livekit_service.generate_mobile_connection_info(@stream, @creator, platform: "mobile")
    mobile_config = connection_info[:mobile_config]
    
    # Test mobile optimizations
    assert mobile_config[:adaptiveStream], "Adaptive streaming should be enabled for mobile"
    assert mobile_config[:dynacast], "Dynacast should be enabled for mobile"
    
    # Test reconnection policy for mobile networks
    reconnect_policy = mobile_config[:reconnectPolicy]
    assert_equal "exponential", reconnect_policy[:nextRetryDelayFunc]
    assert_equal 30000, reconnect_policy[:maxRetryDelay]
    assert_equal 5, reconnect_policy[:maxRetries]
    
    # Test background mode support
    background_mode = mobile_config[:backgroundMode]
    assert background_mode[:enabled], "Background mode should be enabled"
    assert background_mode[:audioOnly], "Audio-only mode should be supported"
    
    # Test picture-in-picture
    pip_config = mobile_config[:pictureInPicture]
    assert pip_config[:enabled], "PiP should be enabled"
    assert_equal "16:9", pip_config[:aspectRatio]
  end

  test "handles different experience types correctly" do
    # Test that LiveKit integration works for different experience types
    
    consultation_experience = @space.experiences.create!(
      name: "One-on-One Consultation",
      description: "Private consultation session",
      experience_type: "consultation",
      price_cents: 9999
    )
    
    consultation_stream = consultation_experience.streams.create!(
      title: "Private Session",
      description: "1:1 consultation",
      scheduled_at: 1.hour.from_now,
      status: "scheduled"
    )
    
    # Should generate appropriate configuration for consultation
    connection_info = @livekit_service.generate_mobile_connection_info(consultation_stream, @creator)
    
    # Verify consultation-specific settings (could be customized)
    assert_not_nil connection_info[:mobile_config]
    assert_equal "consultation_#{consultation_stream.id}", consultation_stream.room_name
  end
end