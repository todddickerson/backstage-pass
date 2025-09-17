require "application_system_test_case"

class CreatorOnboardingSystemTest < ApplicationSystemTestCase
  setup do
    @creator = create(:onboarded_user, first_name: "Creator", last_name: "Test")
  end

  device_test "creator can complete full onboarding and space setup workflow" do
    # Sign in as creator
    login_as(@creator, scope: :user)
    visit root_path

    # Creator should have automatic team and space
    within_team_menu do
      assert_text(@creator.current_team.name)
    end

    # Visit the default space
    visit account_team_spaces_path(@creator.current_team)
    assert_text("Your Spaces")

    # Should see the default space created during onboarding
    default_space = @creator.current_team.primary_space
    assert_text(default_space.name)

    # Click on the space to view it
    click_on default_space.name
    assert_text("Space Details")
    assert_text(default_space.name)
  end

  device_test "creator can create their first experience in their space" do
    login_as(@creator, scope: :user)
    space = @creator.current_team.primary_space

    # Navigate to experiences in the space
    visit account_team_space_experiences_path(@creator.current_team, space)
    assert_text("Experiences")

    # Create a new experience
    click_on "New Experience"
    assert_text("Create Experience")

    fill_in "Name", with: "Live Music Masterclass"
    fill_in "Description", with: "Learn advanced music production techniques"
    select "Live Stream", from: "Experience Type"
    fill_in "Price", with: "19.99"

    click_on "Create Experience"

    # Should be redirected to the experience page
    assert_text("Live Music Masterclass")
    assert_text("Learn advanced music production techniques")
    assert_text("$19.99")
  end

  device_test "creator can create access passes for monetization" do
    login_as(@creator, scope: :user)
    space = @creator.current_team.primary_space

    # Navigate to access passes
    visit account_team_space_access_passes_path(@creator.current_team, space)
    assert_text("Access Passes")

    # Create a new access pass
    click_on "New Access Pass"
    assert_text("Create Access Pass")

    fill_in "Name", with: "VIP Membership"
    fill_in "Description", with: "Premium access to all content"
    select "One Time", from: "Pricing Type"
    fill_in "Price", with: "29.99"
    check "Published"

    click_on "Create Access Pass"

    # Should see the access pass details
    assert_text("VIP Membership")
    assert_text("Premium access to all content")
    assert_text("$29.99")
  end

  device_test "creator can set up streaming for their experience" do
    login_as(@creator, scope: :user)

    # Create an experience first
    space = @creator.current_team.primary_space
    experience = space.experiences.create!(
      name: "Live Coding Session",
      description: "Real-time coding demonstration",
      experience_type: "live_stream",
      price_cents: 1999
    )

    # Navigate to streams for the experience
    visit account_experience_streams_path(experience)
    assert_text("Streams")

    # Create a new stream
    click_on "New Stream"
    assert_text("Create Stream")

    fill_in "Title", with: "Building a Rails App Live"
    fill_in "Description", with: "Watch me build a full Rails application"
    # Set scheduled time to 2 hours from now
    scheduled_time = 2.hours.from_now
    fill_in "Scheduled At", with: scheduled_time.strftime("%Y-%m-%dT%H:%M")

    click_on "Create Stream"

    # Should see stream details
    assert_text("Building a Rails App Live")
    assert_text("Watch me build a full Rails application")
    assert_text("Scheduled")
  end

  device_test "complete creator workflow: space → experience → access pass → stream" do
    login_as(@creator, scope: :user)
    visit root_path

    # Step 1: Verify default space exists
    space = @creator.current_team.primary_space
    visit account_team_space_path(@creator.current_team, space)
    assert_text(space.name)

    # Step 2: Create experience
    visit account_team_space_experiences_path(@creator.current_team, space)
    click_on "New Experience"

    fill_in "Name", with: "Complete Creator Workshop"
    fill_in "Description", with: "End-to-end content creation masterclass"
    select "Live Stream", from: "Experience Type"
    fill_in "Price", with: "49.99"
    click_on "Create Experience"

    experience = Experience.find_by(name: "Complete Creator Workshop")
    assert_not_nil experience

    # Step 3: Create access pass for the space
    visit account_team_space_access_passes_path(@creator.current_team, space)
    click_on "New Access Pass"

    fill_in "Name", with: "Workshop Access"
    fill_in "Description", with: "Access to exclusive workshop content"
    select "One Time", from: "Pricing Type"
    fill_in "Price", with: "29.99"
    check "Published"
    click_on "Create Access Pass"

    access_pass = AccessPass.find_by(name: "Workshop Access")
    assert_not_nil access_pass

    # Step 4: Create stream for the experience
    visit account_experience_streams_path(experience)
    click_on "New Stream"

    fill_in "Title", with: "Live Workshop Stream"
    fill_in "Description", with: "Interactive workshop session"
    scheduled_time = 3.hours.from_now
    fill_in "Scheduled At", with: scheduled_time.strftime("%Y-%m-%dT%H:%M")
    click_on "Create Stream"

    stream = Stream.find_by(title: "Live Workshop Stream")
    assert_not_nil stream

    # Verify the complete flow worked
    assert_text("Live Workshop Stream")
    assert_text("Interactive workshop session")

    # Navigate back to space to see everything
    visit account_team_space_path(@creator.current_team, space)
    assert_text(space.name)

    # Verify creator economy is set up
    assert space.experiences.exists?
    assert space.access_passes.exists?
    assert experience.streams.exists?

    puts "✅ Complete creator workflow validated!"
  end
end
