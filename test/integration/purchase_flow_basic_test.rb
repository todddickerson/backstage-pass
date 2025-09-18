require "test_helper"

class PurchaseFlowBasicTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:onboarded_user)
    @team = create(:team, name: "Creator Team")
    @space = @team.primary_space
    @space.update!(published: true, slug: "test-space")

    # Create an Access Pass
    @access_pass = @space.access_passes.create!(
      name: "Premium Access",
      slug: "premium-access",
      pricing_type: "one_time",
      price_cents: 2999,
      published: true,
      stock_limit: nil
    )

    # Create a free pass for testing
    @free_pass = @space.access_passes.create!(
      name: "Free Trial",
      slug: "free-trial",
      pricing_type: "free",
      price_cents: 0,
      published: true
    )
  end

  test "purchase page requires authentication" do
    # Try to access purchase page without signing in
    get new_space_access_pass_purchase_path(
      space_slug: @space.slug,
      access_pass_slug: @access_pass.slug
    )

    assert_redirected_to new_user_session_path
  end

  test "free access pass can be claimed without payment" do
    sign_in @user

    # Visit free pass purchase page
    get new_space_access_pass_purchase_path(
      space_slug: @space.slug,
      access_pass_slug: @free_pass.slug
    )

    assert_response :success

    # Submit form to claim free pass (without payment details)
    assert_difference "AccessGrant.count", 1 do
      assert_difference "Billing::Purchase.count", 1 do
        post space_access_pass_purchase_path(
          space_slug: @space.slug,
          access_pass_slug: @free_pass.slug
        )
      end
    end

    # Should redirect to space page after successful claim
    assert_redirected_to public_space_path(@space.slug)

    # Verify access grant was created
    grant = AccessGrant.last
    assert_equal @user, grant.user
    assert_equal @space, grant.purchasable
    assert_equal "active", grant.status
    assert_equal @free_pass, grant.access_pass
  end

  test "access grant provides access to space experiences" do
    sign_in @user

    # Create an experience in the space
    experience = @space.experiences.create!(
      name: "Live Stream",
      experience_type: "live_stream",
      price_cents: 0
    )

    # User shouldn't have access initially
    assert_not @space.can_access?(@user)

    # Create access grant
    grant = AccessGrant.create!(
      user: @user,
      team: @team,
      purchasable: @space,
      access_pass: @access_pass,
      status: "active"
    )

    # Now user should have access
    assert @space.can_access?(@user)
    assert grant.grants_access_to?(experience)
  end

  test "expired access grant denies access" do
    # Create a new user who is not part of the team
    new_user = create(:onboarded_user)
    sign_in new_user

    # Create an expired grant
    grant = AccessGrant.create!(
      user: new_user,
      team: @team,
      purchasable: @space,
      access_pass: @access_pass,
      status: "active",
      expires_at: 1.day.ago
    )

    # Debug: Check all grants for this user
    all_grants = new_user.access_grants.where(purchasable: @space)
    puts "Total grants: #{all_grants.count}"
    all_grants.each do |g|
      puts "Grant: status=#{g.status}, expires_at=#{g.expires_at}, created_at=#{g.created_at}"
    end

    # The grant should not be active due to expiration
    assert_equal false, grant.active?
    assert_equal false, @space.can_access?(new_user)
  end

  test "purchase requires valid space and access pass" do
    sign_in @user

    # Try with invalid space
    get new_space_access_pass_purchase_path(
      space_slug: "invalid-space",
      access_pass_slug: @access_pass.slug
    )

    assert_redirected_to root_path

    # Try with invalid access pass
    get new_space_access_pass_purchase_path(
      space_slug: @space.slug,
      access_pass_slug: "invalid-pass"
    )

    assert_redirected_to root_path
  end

  test "user can view free access pass purchase page" do
    sign_in @user

    # User should have a stripe_customer_id
    @user.update!(stripe_customer_id: "cus_test123")

    get new_space_access_pass_purchase_path(
      space_slug: @space.slug,
      access_pass_slug: @free_pass.slug
    )

    assert_response :success
    # Check that the access pass name appears somewhere on the page
    assert_match @free_pass.name, response.body
  end

  test "purchase confirmation shows access pass details" do
    sign_in @user

    # Create an access grant (simulating completed purchase)
    AccessGrant.create!(
      user: @user,
      team: @team,
      purchasable: @space,
      access_pass: @access_pass,
      status: "active"
    )

    # Visit space page
    get public_space_path(@space.slug)
    assert_response :success

    # User should see they have access
    assert @space.can_access?(@user)
  end
end
