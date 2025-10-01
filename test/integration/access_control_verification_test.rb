require "test_helper"

class AccessControlVerificationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # Creator's team and space
    @creator_team = create(:team, name: "Creator Team")
    @creator_space = @creator_team.primary_space
    @creator_space.update!(published: true, slug: "creator-space")

    # Create an experience and stream
    @experience = @creator_space.experiences.create!(
      name: "Premium Live Stream",
      slug: "premium-stream",
      experience_type: "live_stream",
      price_cents: 1999
    )

    @stream = @experience.streams.create!(
      title: "Test Stream",
      scheduled_at: 1.hour.from_now,
      status: "live"
    )

    # Create access pass for the space
    @paid_pass = @creator_space.access_passes.create!(
      name: "Premium Access",
      slug: "premium-access",
      pricing_type: "one_time",
      price_cents: 2999,
      published: true
    )

    # Create a viewer user (not part of creator team)
    @viewer = create(:onboarded_user)
  end

  # Test: Viewer with valid access grant can access purchased streams
  test "viewer with valid access grant can access stream" do
    sign_in @viewer

    # Create active access grant for the viewer
    grant = AccessGrant.create!(
      user: @viewer,
      team: @creator_team,
      purchasable: @creator_space,
      access_pass: @paid_pass,
      status: "active"
    )

    # Verify grant is active
    assert grant.active?, "Grant should be active"

    # Verify viewer can access the space
    assert @creator_space.can_access?(@viewer), "Viewer should have access to space"

    # Verify viewer can access the experience
    assert @experience.accessible_by?(@viewer), "Viewer should have access to experience"

    # Verify viewer can view the stream
    assert @stream.can_view?(@viewer), "Viewer should be able to view the stream"

    # Test HTTP access to experience page
    get public_space_experience_path(
      space_slug: @creator_space.slug,
      experience_slug: @experience.slug
    )
    assert_response :success, "Viewer should be able to access experience page"
  end

  # Test: Viewer without access grant is blocked from unpurchased streams
  test "viewer without access grant cannot access stream" do
    sign_in @viewer

    # Viewer has no access grant
    assert_not @creator_space.can_access?(@viewer), "Viewer should not have space access"
    assert_not @experience.accessible_by?(@viewer), "Viewer should not have experience access"
    assert_not @stream.can_view?(@viewer), "Viewer should not be able to view stream"

    # Test HTTP access to experience page - should be redirected
    get public_space_experience_path(
      space_slug: @creator_space.slug,
      experience_slug: @experience.slug
    )
    assert_redirected_to public_space_path(@creator_space.slug)
    follow_redirect!
    assert_match "Access Pass required", flash[:alert]
  end

  # Test: Viewer with expired access grant is blocked
  test "viewer with expired access grant cannot access stream" do
    sign_in @viewer

    # Create expired access grant
    expired_grant = AccessGrant.create!(
      user: @viewer,
      team: @creator_team,
      purchasable: @creator_space,
      access_pass: @paid_pass,
      status: "active",
      expires_at: 1.day.ago
    )

    # Verify grant is not active
    assert_not expired_grant.active?, "Expired grant should not be active"

    # Verify all access methods properly check expiration
    assert_not @creator_space.can_access?(@viewer), "Viewer with expired grant should not have space access"
    assert_not @experience.accessible_by?(@viewer), "Viewer with expired grant should not have experience access"
    assert_not @stream.can_view?(@viewer), "Viewer with expired grant should not be able to view stream"

    # Test HTTP access - should be redirected
    get public_space_experience_path(
      space_slug: @creator_space.slug,
      experience_slug: @experience.slug
    )
    assert_redirected_to public_space_path(@creator_space.slug)
  end

  # Test: Viewer with cancelled access grant is blocked
  test "viewer with cancelled access grant cannot access stream" do
    sign_in @viewer

    # Create cancelled access grant
    cancelled_grant = AccessGrant.create!(
      user: @viewer,
      team: @creator_team,
      purchasable: @creator_space,
      access_pass: @paid_pass,
      status: "cancelled"
    )

    # Verify grant is not active
    assert_not cancelled_grant.active?, "Cancelled grant should not be active"

    # Verify access is denied
    assert_not @creator_space.can_access?(@viewer), "Viewer with cancelled grant should not have access"
    assert_not @experience.accessible_by?(@viewer), "Viewer with cancelled grant should not have experience access"
    assert_not @stream.can_view?(@viewer), "Viewer with cancelled grant should not be able to view stream"
  end

  # Test: Viewer with refunded access grant is blocked
  test "viewer with refunded access grant cannot access stream" do
    sign_in @viewer

    # Create refunded access grant
    refunded_grant = AccessGrant.create!(
      user: @viewer,
      team: @creator_team,
      purchasable: @creator_space,
      access_pass: @paid_pass,
      status: "refunded"
    )

    # Verify grant is not active
    assert_not refunded_grant.active?, "Refunded grant should not be active"

    # Verify access is denied
    assert_not @creator_space.can_access?(@viewer), "Viewer with refunded grant should not have access"
    assert_not @experience.accessible_by?(@viewer), "Viewer with refunded grant should not have experience access"
    assert_not @stream.can_view?(@viewer), "Viewer with refunded grant should not be able to view stream"
  end

  # Test: Team members (admin/editor) always have access
  test "team admin has access to all streams" do
    admin_user = create(:onboarded_user)
    membership = admin_user.memberships.find_by(team: admin_user.current_team)
    membership.update!(team: @creator_team)
    membership.update!(role_ids: [Role.admin.id])

    sign_in admin_user

    # Admin should have access without access grant
    assert @creator_space.can_access?(admin_user), "Admin should have space access"
    assert @experience.accessible_by?(admin_user), "Admin should have experience access"
    assert @stream.can_view?(admin_user), "Admin should be able to view stream"
  end

  # Test: Free access pass logic
  test "free access pass grants immediate access" do
    # Create free access pass
    free_pass = @creator_space.access_passes.create!(
      name: "Free Trial",
      slug: "free-trial",
      pricing_type: "free",
      price_cents: 0,
      published: true
    )

    sign_in @viewer

    # Claim free pass
    post space_access_pass_purchase_path(
      space_slug: @creator_space.slug,
      access_pass_slug: free_pass.slug
    )

    # Should create access grant
    grant = @viewer.access_grants.last
    assert grant.present?, "Free pass claim should create access grant"
    assert_equal "active", grant.status
    assert_equal @creator_space, grant.purchasable

    # Should grant access immediately
    assert @creator_space.can_access?(@viewer), "Free pass should grant space access"
    assert @experience.accessible_by?(@viewer), "Free pass should grant experience access"
    assert @stream.can_view?(@viewer), "Free pass should grant stream viewing access"
  end

  # Test: Experience-specific access grant
  test "experience-specific access grant only grants access to that experience" do
    sign_in @viewer

    # Create another experience in the same space
    other_experience = @creator_space.experiences.create!(
      name: "Other Experience",
      slug: "other-experience",
      experience_type: "live_stream",
      price_cents: 0
    )

    # Create access grant for specific experience only
    AccessGrant.create!(
      user: @viewer,
      team: @creator_team,
      purchasable: @experience,  # Grant for specific experience, not space
      access_pass: @paid_pass,
      status: "active"
    )

    # Should have access to the specific experience
    assert @experience.accessible_by?(@viewer), "Should have access to granted experience"
    assert @stream.can_view?(@viewer), "Should be able to view stream in granted experience"

    # Should NOT have access to other experiences in the space
    assert_not other_experience.accessible_by?(@viewer), "Should not have access to other experiences"
  end

  # Test: Space-level access grant gives access to all experiences
  test "space-level access grant gives access to all experiences in space" do
    sign_in @viewer

    # Create another experience in the same space
    other_experience = @creator_space.experiences.create!(
      name: "Other Experience",
      slug: "other-experience",
      experience_type: "live_stream",
      price_cents: 0
    )

    other_stream = other_experience.streams.create!(
      title: "Other Stream",
      scheduled_at: 1.hour.from_now,
      status: "live"
    )

    # Create space-level access grant
    AccessGrant.create!(
      user: @viewer,
      team: @creator_team,
      purchasable: @creator_space,  # Grant for entire space
      access_pass: @paid_pass,
      status: "active"
    )

    # Should have access to ALL experiences in the space
    assert @experience.accessible_by?(@viewer), "Should have access to first experience"
    assert @stream.can_view?(@viewer), "Should be able to view first stream"

    assert other_experience.accessible_by?(@viewer), "Should have access to other experience"
    assert other_stream.can_view?(@viewer), "Should be able to view other stream"
  end

  # Test: Unauthenticated users are blocked
  test "unauthenticated users cannot access paid streams" do
    # No sign in

    # Try to access experience page
    get public_space_experience_path(
      space_slug: @creator_space.slug,
      experience_slug: @experience.slug
    )

    # Should redirect to sign in
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_match "sign in", response.body.downcase
  end
end
