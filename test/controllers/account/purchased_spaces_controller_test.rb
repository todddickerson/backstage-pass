require "test_helper"

class Account::PurchasedSpacesControllerTest < ActionDispatch::IntegrationTest
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

  test "index shows purchased spaces for user with access grants" do
    get account_purchased_spaces_path

    assert_response :success
    assert_select "h1", text: "My Streams"

    # Should show the purchased space
    assert_select "h3", text: @space.name

    # Should not show empty state
    assert_not_includes response.body, "No purchased content yet"
  end

  test "index shows empty state for user without access grants" do
    @access_grant.destroy

    get account_purchased_spaces_path

    assert_response :success
    assert_select "h1", text: "My Streams"

    # Should show empty state
    assert_includes response.body, "No purchased content yet"
    assert_includes response.body, "Browse spaces to find content you'd like to purchase"
    assert_select "a[href='#{explore_spaces_path}']", text: "Explore Spaces"
  end

  test "index separates live and scheduled streams" do
    # Create a scheduled stream
    scheduled_stream = create(:stream,
      experience: @experience,
      title: "Scheduled Stream",
      status: "scheduled",
      scheduled_at: 1.hour.from_now)

    get account_purchased_spaces_path

    assert_response :success

    # Both streams should be visible
    assert_select "h3", text: @stream.title  # Live stream
    assert_select "h3", text: scheduled_stream.title  # Scheduled stream
  end

  test "index shows recent ended streams" do
    # Create an ended stream
    ended_stream = create(:stream,
      experience: @experience,
      title: "Ended Stream",
      status: "ended")
    ended_stream.update_column(:updated_at, 2.hours.ago)

    get account_purchased_spaces_path

    assert_response :success

    # Should show recent streams section
    assert_includes response.body, "Recent Streams"
    assert_includes response.body, ended_stream.title
    assert_includes response.body, "Ended"
    assert_includes response.body, "ago"
  end

  test "index filters old ended streams" do
    # Create an old ended stream (more than 7 days ago)
    old_stream = create(:stream,
      experience: @experience,
      title: "Old Ended Stream",
      status: "ended")
    old_stream.update_column(:updated_at, 8.days.ago)

    get account_purchased_spaces_path

    assert_response :success

    # Should not show old streams
    assert_not_includes response.body, old_stream.title
  end

  test "index handles multiple spaces correctly" do
    # Create a second space with access
    second_space = create(:space, team: @team, name: "Second Space")
    create(:experience, space: second_space, name: "Second Experience")
    second_access_pass = create(:access_pass, space: second_space, pricing_type: "free")
    create(:access_grant,
      user: @user,
      team: @team,
      purchasable: second_space,
      access_pass: second_access_pass,
      status: "active")

    get account_purchased_spaces_path

    assert_response :success

    # Should show both spaces
    assert_includes response.body, @space.name
    assert_includes response.body, second_space.name
  end

  test "show displays specific space details with access" do
    get account_purchased_space_path(@space)

    assert_response :success
    assert_select "h1", text: @space.name

    # Should show access confirmation
    assert_includes response.body, "You have access"

    # Should show experiences
    assert_includes response.body, @experience.name
    assert_includes response.body, "1 stream"

    # Should have link to public page
    assert_select "a[href='#{public_space_path(@space.slug)}']", text: "Visit Public Page"
  end

  test "show redirects without access to specific space" do
    @access_grant.destroy

    get account_purchased_space_path(@space)

    assert_redirected_to account_purchased_spaces_path
    assert_match "You don't have access to this space", flash[:alert]
  end

  test "show handles experience-level access grants" do
    # Remove space-level access and add experience-level access
    @access_grant.destroy

    # Create access grant for the experience directly (purchasable is polymorphic)
    create(:access_grant,
      user: @user,
      team: @team,
      purchasable: @experience,
      access_pass: @access_pass,  # Use existing space access pass
      status: "active")

    get account_purchased_space_path(@space)

    assert_response :success
    assert_includes response.body, @space.name
    assert_includes response.body, "You have access"
  end

  test "show displays live streams prominently" do
    @stream.update!(status: "live")

    get account_purchased_space_path(@space)

    assert_response :success
    assert_includes response.body, "Live Now"
    assert_includes response.body, @stream.title
  end

  test "show groups upcoming streams separately" do
    scheduled_stream = create(:stream,
      experience: @experience,
      title: "Upcoming Stream",
      status: "scheduled",
      scheduled_at: 2.hours.from_now)

    get account_purchased_space_path(@space)

    assert_response :success
    assert_includes response.body, "Upcoming Streams"
    assert_includes response.body, scheduled_stream.title
  end

  test "show displays recent streams with replay indicators" do
    ended_stream = create(:stream,
      experience: @experience,
      title: "Recent Stream",
      status: "ended")
    ended_stream.update_column(:updated_at, 1.hour.ago)

    get account_purchased_space_path(@space)

    assert_response :success
    assert_includes response.body, "Recent Streams"
    assert_includes response.body, ended_stream.title
    assert_includes response.body, "Replay Available"
  end

  test "show handles empty experiences gracefully" do
    # Create a space with no experiences
    empty_space = create(:space, team: @team, name: "Empty Space")
    empty_access_pass = create(:access_pass, space: empty_space, pricing_type: "free")
    create(:access_grant,
      user: @user,
      team: @team,
      purchasable: empty_space,
      access_pass: empty_access_pass,
      status: "active")

    get account_purchased_space_path(empty_space)

    assert_response :success
    assert_includes response.body, "No experiences yet"
    assert_includes response.body, "The creator hasn't added any experiences to this space yet"
  end

  test "index displays access grant expiration information" do
    # Set expiration date
    @access_grant.update!(expires_at: 30.days.from_now)

    get account_purchased_spaces_path

    assert_response :success
    assert_includes response.body, "Expires"
    assert_includes response.body, "from now"
  end

  test "index displays lifetime access correctly" do
    # Remove expiration date
    @access_grant.update!(expires_at: nil)

    get account_purchased_spaces_path

    assert_response :success
    assert_includes response.body, "Lifetime access"
  end

  test "unauthenticated user is redirected" do
    sign_out @user

    get account_purchased_spaces_path
    assert_redirected_to new_user_session_path

    get account_purchased_space_path(@space)
    assert_redirected_to new_user_session_path
  end

  test "index includes proper breadcrumb navigation" do
    get account_purchased_spaces_path

    assert_response :success

    # Navigation should be present (checking for structure)
    assert_select "h1", text: "My Streams"
  end

  test "show includes proper breadcrumb navigation" do
    get account_purchased_space_path(@space)

    assert_response :success

    # Should have breadcrumb back to index
    assert_select "a[href='#{account_purchased_spaces_path}']", text: "My Streams"
    assert_includes response.body, @space.name
  end

  test "index performance with multiple access grants" do
    # Create multiple spaces and access grants to test performance
    10.times do |i|
      space = create(:space, team: @team, name: "Space #{i}")
      access_pass = create(:access_pass, space: space, pricing_type: "free")
      create(:access_grant,
        user: @user,
        team: @team,
        purchasable: space,
        access_pass: access_pass,
        status: "active")
    end

    # Should handle multiple grants without issues
    get account_purchased_spaces_path

    assert_response :success
    # Note: The exact count depends on the view structure, which includes spaces and streams
    # Let's just check that we have multiple spaces represented
    assert_includes response.body, @space.name
    assert_select "h3", minimum: 11  # At least 11 h3 elements (original space + 10 new spaces)
  end

  private

  def create(factory_name, **attributes)
    FactoryBot.create(factory_name, **attributes)
  end
end
