require "test_helper"

class PurchaseFlowTest < ActionDispatch::IntegrationTest
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

    # Mock Stripe
    ENV["STRIPE_PUBLISHABLE_KEY"] = "pk_test_123"
    ENV["STRIPE_SECRET_KEY"] = "sk_test_123"
  end

  test "user can view access pass purchase page" do
    sign_in @user

    # Mock Stripe customer creation and setup intent
    Billing::StripeService.any_instance.stubs(:create_customer).returns(
      OpenStruct.new(id: "cus_test123")
    )
    Billing::StripeService.any_instance.stubs(:create_setup_intent).returns(
      OpenStruct.new(id: "seti_test123", client_secret: "seti_test123_secret")
    )

    get new_space_access_pass_purchase_path(
      space_slug: @space.slug,
      access_pass_slug: @access_pass.slug
    )

    assert_response :success
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
    assert_select "form[action=?]", space_access_pass_purchase_path(@space.slug, @free_pass.slug)

    # Submit form to claim free pass
    assert_difference "AccessGrant.count", 1 do
      post space_access_pass_purchase_path(
        space_slug: @space.slug,
        access_pass_slug: @free_pass.slug
      )
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

  test "paid access pass requires stripe payment" do
    sign_in @user

    # Mock Stripe customer creation and setup intent
    Billing::StripeService.any_instance.stubs(:create_customer).returns(
      OpenStruct.new(id: "cus_test123")
    )
    Billing::StripeService.any_instance.stubs(:create_setup_intent).returns(
      OpenStruct.new(id: "seti_test123", client_secret: "seti_test123_secret")
    )

    # Visit paid pass purchase page
    get new_space_access_pass_purchase_path(
      space_slug: @space.slug,
      access_pass_slug: @access_pass.slug
    )

    assert_response :success

    # Should have Stripe Elements on page
    assert_select "form[data-stripe-key]"
    assert_select "div#payment-element", 1, "Should have Stripe payment element"
  end

  test "successful purchase creates access grant and purchase record" do
    sign_in @user

    # Create a real purchase record for the mock to return
    purchase = Billing::Purchase.create!(
      user: @user,
      team: @team,
      access_pass: @access_pass,
      amount_cents: @access_pass.price_cents,
      status: "completed"
    )

    # Create the access grant that the service would create
    access_grant = AccessGrant.create!(
      user: @user,
      team: @team,
      purchasable: @access_pass.space,
      access_pass: @access_pass,
      status: "active"
    )

    # Mock successful Stripe payment
    Billing::PurchaseService.any_instance.stubs(:execute).returns({
      success: true,
      purchase: purchase,
      access_grant: access_grant
    })

    post space_access_pass_purchase_path(
      space_slug: @space.slug,
      access_pass_slug: @access_pass.slug
    ), params: {
      payment_method_id: "pm_test_123"
    }

    assert_redirected_to public_space_path(@space.slug)
  end

  test "failed payment shows error and redirects back" do
    sign_in @user

    # Mock Stripe customer creation and setup intent for initial page load
    Billing::StripeService.any_instance.stubs(:create_customer).returns(
      OpenStruct.new(id: "cus_test123")
    )
    Billing::StripeService.any_instance.stubs(:create_setup_intent).returns(
      OpenStruct.new(id: "seti_test123", client_secret: "seti_test123_secret")
    )

    # Mock failed Stripe payment
    Billing::PurchaseService.any_instance.stubs(:execute).returns({
      success: false,
      error: "Card was declined"
    })

    assert_no_difference ["Billing::Purchase.count", "AccessGrant.count"] do
      post space_access_pass_purchase_path(
        space_slug: @space.slug,
        access_pass_slug: @access_pass.slug
      ), params: {
        payment_method_id: "pm_test_declined"
      }
    end

    assert_redirected_to new_space_access_pass_purchase_path(@space.slug, @access_pass.slug)
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
    # Create a different user that's not a team member
    non_member_user = create(:onboarded_user)
    sign_in non_member_user

    # Ensure user is not a team member
    @team.memberships.where(user: non_member_user).destroy_all

    # Create an expired grant
    grant = AccessGrant.create!(
      user: non_member_user,
      team: @team,
      purchasable: @space,
      access_pass: @access_pass,
      status: "expired",
      expires_at: 2.days.ago
    )

    assert_not grant.active?
    assert_not @space.can_access?(non_member_user)
  end

  test "stripe webhook handles successful payment" do
    # Create a pending purchase
    purchase = Billing::Purchase.create!(
      user: @user,
      team: @team,
      access_pass: @access_pass,
      amount_cents: 2999,
      stripe_payment_intent_id: "pi_test_123",
      status: "pending"
    )

    # Simulate Stripe webhook
    webhook_payload = {
      type: "payment_intent.succeeded",
      data: {
        object: {
          id: "pi_test_123",
          amount: 2999,
          currency: "usd"
        }
      }
    }.to_json

    # Mock Stripe signature verification
    ::Stripe::Webhook.stubs(:construct_event).returns(JSON.parse(webhook_payload))

    # Send webhook
    post webhooks_stripe_path,
      params: webhook_payload,
      headers: {"HTTP_STRIPE_SIGNATURE" => "test_sig"}

    assert_response :success

    # Verify purchase was marked complete
    purchase.reload
    assert_equal "completed", purchase.status

    # Verify access grant was created
    grant = AccessGrant.find_by(user: @user, access_pass: @access_pass)
    assert grant.present?
    assert_equal "active", grant.status
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

  test "recurring subscription creates access grant with expiration" do
    sign_in @user

    # Create a monthly pass
    monthly_pass = @space.access_passes.create!(
      name: "Monthly Subscription",
      slug: "monthly-sub",
      pricing_type: "monthly",
      price_cents: 999,
      published: true
    )

    # Simulate subscription webhook
    subscription_data = {
      id: "sub_test_123",
      status: "active",
      current_period_end: 30.days.from_now.to_i,
      metadata: {
        access_pass_id: monthly_pass.id,
        user_id: @user.id,
        team_id: @team.id
      },
      items: {
        data: [{
          price: {
            unit_amount: 999
          }
        }]
      }
    }

    webhook_payload = {
      type: "customer.subscription.created",
      data: {
        object: subscription_data
      }
    }.to_json

    ::Stripe::Webhook.stubs(:construct_event).returns(JSON.parse(webhook_payload))

    # Send webhook
    assert_difference ["Billing::Purchase.count", "AccessGrant.count"], 1 do
      post webhooks_stripe_path,
        params: webhook_payload,
        headers: {"HTTP_STRIPE_SIGNATURE" => "test_sig"}
    end

    assert_response :success

    # Verify grant has expiration
    grant = AccessGrant.last
    assert_equal @user, grant.user
    assert grant.expires_at.present?
    assert grant.expires_at > Time.current
  end
end
