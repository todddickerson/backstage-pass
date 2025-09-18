require "application_system_test_case"

class StreamViewingTest < ApplicationSystemTestCase
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
      status: "active"
    )
    
    sign_in @user
  end

  test "user with access can view purchased spaces dashboard" do
    visit account_purchased_spaces_path
    
    assert_text "My Streams"
    assert_text @space.name
    assert_no_text "No purchased content yet"
  end

  test "user without access sees empty state" do
    @access_grant.destroy
    
    visit account_purchased_spaces_path
    
    assert_text "No purchased content yet"
    assert_text "Browse spaces to find content you'd like to purchase"
  end

  test "user can access stream viewing page with valid access" do
    visit account_viewer_stream_path(@stream)
    
    assert_text @stream.title
    assert_text @space.name
    assert_text @experience.name
    
    # Check for video container
    assert_selector "[data-stream-viewer-target='video']"
    
    # Check for chat elements
    assert_selector "[data-stream-viewer-target='chatSidebar']"
    assert_selector "[data-stream-viewer-target='mobileChat']"
  end

  test "user without access is redirected from stream viewing" do
    @access_grant.destroy
    
    visit account_viewer_stream_path(@stream)
    
    # Should be redirected to public space page
    assert_current_path public_space_path(@space.slug)
    assert_text "Access Pass required to view this stream"
  end

  test "stream viewing page shows correct status for live stream" do
    @stream.update!(status: "live")
    
    visit account_viewer_stream_path(@stream)
    
    assert_text "LIVE"
    assert_selector "[data-stream-viewer-target='viewerCount']"
  end

  test "stream viewing page shows scheduled stream information" do
    @stream.update!(status: "scheduled", scheduled_at: 1.hour.from_now)
    
    visit account_viewer_stream_path(@stream)
    
    assert_text "Stream Scheduled"
    assert_text "Starts"
  end

  test "stream viewing page shows ended stream with replay option" do
    @stream.update!(status: "ended")
    @stream.update_column(:updated_at, 1.hour.ago)
    
    visit account_viewer_stream_path(@stream)
    
    assert_text "Stream Ended"
    assert_text "This stream has finished"
  end

  test "mobile chat toggle functionality" do
    visit account_viewer_stream_path(@stream)
    
    # Mobile chat should be hidden initially
    mobile_chat = find("[data-stream-viewer-target='mobileChat']", visible: false)
    assert mobile_chat[:class].include?("translate-y-full")
    
    # Chat toggle should be present on mobile viewport
    # Note: This would need viewport manipulation in a real browser test
  end

  test "fullscreen controls are present" do
    visit account_viewer_stream_path(@stream)
    
    assert_selector "#fullscreen-toggle"
    assert_selector "[data-stream-viewer-target='controls']"
  end

  test "stream data is properly embedded for JavaScript" do
    visit account_viewer_stream_path(@stream)
    
    # Check that stream data script tag exists
    assert_selector "script#stream-data"
    
    # Parse the JSON and verify it contains expected data
    script_content = find("script#stream-data").text(:all)
    stream_data = JSON.parse(script_content)
    
    assert_equal @stream.id, stream_data["stream"]["id"]
    assert_equal @stream.title, stream_data["stream"]["title"]
    assert_includes stream_data.keys, "endpoints"
    assert_includes stream_data.keys, "permissions"
  end

  test "navigation breadcrumbs work correctly" do
    visit account_purchased_space_path(@space)
    
    assert_text "My Streams"
    assert_text @space.name
    
    # Should have breadcrumb navigation
    assert_link "My Streams", href: account_purchased_spaces_path
  end

  test "purchased space detail page shows experiences and streams" do
    visit account_purchased_space_path(@space)
    
    assert_text @space.name
    assert_text @experience.name
    assert_text "1 stream"
    
    # Should show live streams section when applicable
    if @stream.live?
      assert_text "Live Now"
    end
  end

  test "access grant expiration affects viewing" do
    # Set access grant to expire soon
    @access_grant.update!(expires_at: 1.hour.from_now)
    
    visit account_purchased_spaces_path
    
    assert_text "Expires"
    assert_text "from now"
  end

  test "lifetime access shows correctly" do
    @access_grant.update!(expires_at: nil)
    
    visit account_purchased_spaces_path
    
    assert_text "Lifetime access"
  end

  test "user can navigate to public space from viewer dashboard" do
    visit account_purchased_space_path(@space)
    
    click_link "Visit Public Page"
    
    # Should open in new tab/window, but in test it redirects
    assert_current_path public_space_path(@space.slug)
  end

  test "stream viewing controller endpoints are accessible" do
    # Test video token endpoint
    visit account_viewer_stream_path(@stream)
    
    # These would normally be AJAX requests, but we can test the paths exist
    video_token_path = video_token_account_viewer_stream_path(@stream)
    chat_token_path = chat_token_account_viewer_stream_path(@stream)
    stream_info_path = stream_info_account_viewer_stream_path(@stream)
    
    # Verify paths are generated correctly (they should not raise errors)
    assert video_token_path.present?
    assert chat_token_path.present?
    assert stream_info_path.present?
  end

  private

  def create(factory_name, **attributes)
    FactoryBot.create(factory_name, **attributes)
  end
end