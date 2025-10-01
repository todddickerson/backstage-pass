require "test_helper"

class Public::PurchasesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    @team = create(:team)
    @space = create(:space, team: @team, published: true)
    @free_pass = create(:access_pass, space: @space, name: "Free Access", pricing_type: "free", price_cents: 0)
    @one_time_pass = create(:access_pass, space: @space, name: "One-Time Access", pricing_type: "one_time", price_cents: 1999)
    @monthly_pass = create(:access_pass, space: @space, name: "Monthly Subscription", pricing_type: "monthly", price_cents: 999)

    sign_in @user
  end

  # NEW ACTION TESTS

  test "new redirects to sign in if not authenticated" do
    sign_out @user

    get new_space_access_pass_purchase_path(@space.slug, @free_pass.slug)

    assert_redirected_to new_user_session_path
  end

  test "new loads access pass and displays purchase form for free pass" do
    get new_space_access_pass_purchase_path(@space.slug, @free_pass.slug)

    assert_response :success
    assert_not_nil assigns(:access_pass)
    assert_equal @free_pass, assigns(:access_pass)
    assert_nil assigns(:setup_intent) # Free pass doesn't need Stripe
  end

  test "new creates setup intent for paid pass" do
    # Mock Stripe SetupIntent creation
    setup_intent = OpenStruct.new(
      id: "seti_test_123",
      client_secret: "seti_test_123_secret"
    )

    Billing::StripeService.any_instance.expects(:create_setup_intent).returns(setup_intent)

    get new_space_access_pass_purchase_path(@space.slug, @one_time_pass.slug)

    assert_response :success
    assert_not_nil assigns(:setup_intent)
    assert_equal "seti_test_123", assigns(:setup_intent).id
  end

  test "new creates Stripe customer if user doesn't have one" do
    assert_nil @user.stripe_customer_id

    customer = OpenStruct.new(
      id: "cus_test_123",
      email: @user.email
    )

    Billing::StripeService.any_instance.expects(:create_customer).returns(customer)
    Billing::StripeService.any_instance.expects(:create_setup_intent).returns(
      OpenStruct.new(id: "seti_test", client_secret: "secret")
    )

    get new_space_access_pass_purchase_path(@space.slug, @one_time_pass.slug)

    @user.reload
    assert_equal "cus_test_123", @user.stripe_customer_id
  end

  test "new redirects for unpublished space" do
    unpublished_space = create(:space, team: @team, published: false)
    unpublished_pass = create(:access_pass, space: unpublished_space)

    get new_space_access_pass_purchase_path(unpublished_space.slug, unpublished_pass.slug)

    assert_redirected_to root_path
    assert_not_nil flash[:alert]
  end

  test "new redirects for nonexistent access pass" do
    get new_space_access_pass_purchase_path(@space.slug, "nonexistent-slug")

    assert_redirected_to root_path
    assert_not_nil flash[:alert]
  end

  # CREATE ACTION TESTS - FREE PASS

  test "create successfully processes free access pass" do
    assert_difference ["Billing::Purchase.count", "AccessGrant.count"], 1 do
      post space_access_pass_purchase_path(@space.slug, @free_pass.slug)
    end

    assert_redirected_to public_space_path(@space.slug)
    assert_equal "Purchase completed successfully!", flash[:notice]

    purchase = Billing::Purchase.last
    assert_equal @user, purchase.user
    assert_equal @free_pass, purchase.access_pass
    assert_equal "completed", purchase.status
    assert_equal 0, purchase.amount_cents

    grant = AccessGrant.last
    assert_equal @user, grant.user
    assert_equal @free_pass, grant.access_pass
    assert_equal @space, grant.purchasable
    assert_equal "active", grant.status
    assert_nil grant.expires_at
  end

  test "create adds buyer to team for free pass" do
    assert_difference "Membership.count", 1 do
      post space_access_pass_purchase_path(@space.slug, @free_pass.slug)
    end

    membership = @team.memberships.find_by(user: @user)
    assert_not_nil membership
    assert_includes membership.role_ids, "buyer"
  end

  # CREATE ACTION TESTS - ONE-TIME PURCHASE

  test "create successfully processes one-time purchase with payment method" do
    # Mock Stripe payment intent creation and confirmation
    payment_intent = OpenStruct.new(
      id: "pi_test_123",
      status: "succeeded",
      amount: 1999,
      currency: "usd"
    )

    Billing::StripeService.any_instance.expects(:create_payment_intent).returns(payment_intent)
    Billing::StripeService.any_instance.expects(:confirm_payment_intent).returns(payment_intent)

    assert_difference ["Billing::Purchase.count", "AccessGrant.count"], 1 do
      post space_access_pass_purchase_path(@space.slug, @one_time_pass.slug),
        params: {payment_method_id: "pm_test_123"}
    end

    assert_redirected_to public_space_path(@space.slug)

    purchase = Billing::Purchase.last
    assert_equal "completed", purchase.status
    assert_equal 1999, purchase.amount_cents
    assert_equal "pi_test_123", purchase.stripe_payment_intent_id
  end

  test "create handles failed payment for one-time purchase" do
    # Mock failed payment
    failed_intent = OpenStruct.new(
      id: "pi_test_failed",
      status: "requires_payment_method",
      amount: 1999
    )

    Billing::StripeService.any_instance.expects(:create_payment_intent).returns(failed_intent)
    Billing::StripeService.any_instance.expects(:confirm_payment_intent).returns(failed_intent)

    assert_difference "Billing::Purchase.count", 1 do
      assert_no_difference "AccessGrant.count" do
        post space_access_pass_purchase_path(@space.slug, @one_time_pass.slug),
          params: {payment_method_id: "pm_test_failed"}
      end
    end

    assert_redirected_to new_space_access_pass_purchase_path(@space.slug, @one_time_pass.slug)
    assert_equal "Payment failed", flash[:alert]

    purchase = Billing::Purchase.last
    assert_equal "failed", purchase.status
  end

  test "create handles Stripe errors gracefully" do
    # Mock a Stripe CardError (inherits from Stripe::StripeError)
    Billing::StripeService.any_instance.expects(:create_payment_intent).raises(
      ::Stripe::CardError.new("Card declined", "card")
    )

    assert_no_difference ["Billing::Purchase.count", "AccessGrant.count"] do
      post space_access_pass_purchase_path(@space.slug, @one_time_pass.slug),
        params: {payment_method_id: "pm_test_123"}
    end

    assert_redirected_to new_space_access_pass_purchase_path(@space.slug, @one_time_pass.slug)
    assert_not_nil flash[:alert]
  end

  # CREATE ACTION TESTS - SUBSCRIPTION

  test "create successfully processes monthly subscription" do
    # Set up Stripe price IDs
    @monthly_pass.update!(
      stripe_monthly_price_id: "price_monthly_test"
    )

    # Mock subscription creation
    subscription = OpenStruct.new(
      id: "sub_test_123",
      status: "active",
      items: OpenStruct.new(
        data: [
          OpenStruct.new(
            price: OpenStruct.new(
              unit_amount: 999
            )
          )
        ]
      ),
      current_period_end: 1.month.from_now.to_i
    )

    Billing::StripeService.any_instance.expects(:create_subscription).returns(subscription)

    assert_difference ["Billing::Purchase.count", "AccessGrant.count"], 1 do
      post space_access_pass_purchase_path(@space.slug, @monthly_pass.slug),
        params: {payment_method_id: "pm_test_123"}
    end

    purchase = Billing::Purchase.last
    assert_equal "completed", purchase.status
    assert_equal "sub_test_123", purchase.stripe_charge_id

    grant = AccessGrant.last
    assert_not_nil grant.expires_at
    assert grant.expires_at > Time.current
  end

  test "create handles subscription requiring payment method" do
    @monthly_pass.update!(stripe_monthly_price_id: "price_monthly_test")

    subscription = OpenStruct.new(
      id: "sub_test_incomplete",
      status: "incomplete",
      items: OpenStruct.new(
        data: [OpenStruct.new(price: OpenStruct.new(unit_amount: 999))]
      )
    )

    Billing::StripeService.any_instance.expects(:create_subscription).returns(subscription)

    assert_difference "Billing::Purchase.count", 1 do
      assert_no_difference "AccessGrant.count" do
        post space_access_pass_purchase_path(@space.slug, @monthly_pass.slug),
          params: {payment_method_id: "pm_test_123"}
      end
    end

    assert_redirected_to new_space_access_pass_purchase_path(@space.slug, @monthly_pass.slug)
  end

  # WEBHOOK TESTS

  test "stripe webhook handles payment_intent.succeeded" do
    purchase = create(:billing_purchase,
      user: @user,
      team: @team,
      access_pass: @one_time_pass,
      stripe_payment_intent_id: "pi_webhook_test",
      status: "pending")

    payload = {
      type: "payment_intent.succeeded",
      data: {
        object: {
          id: "pi_webhook_test"
        }
      }
    }.to_json

    # Mock Stripe webhook verification
    event_data = JSON.parse(payload)
    event = OpenStruct.new(
      type: event_data["type"],
      data: OpenStruct.new(
        object: OpenStruct.new(event_data["data"]["object"])
      )
    )
    ::Stripe::Webhook.expects(:construct_event).returns(event)

    assert_difference "AccessGrant.count", 1 do
      post webhooks_stripe_path,
        params: payload,
        headers: {"STRIPE-SIGNATURE" => "test_signature"}
    end

    assert_response :success

    purchase.reload
    assert_equal "completed", purchase.status

    grant = AccessGrant.find_by(user: @user, access_pass: @one_time_pass)
    assert_not_nil grant
    assert_equal "active", grant.status
  end

  test "stripe webhook handles payment_intent.payment_failed" do
    purchase = create(:billing_purchase,
      user: @user,
      team: @team,
      access_pass: @one_time_pass,
      stripe_payment_intent_id: "pi_failed_test",
      status: "pending")

    payload = {
      type: "payment_intent.payment_failed",
      data: {
        object: {
          id: "pi_failed_test"
        }
      }
    }.to_json

    event_data = JSON.parse(payload)
    event = OpenStruct.new(type: event_data["type"], data: OpenStruct.new(object: OpenStruct.new(event_data["data"]["object"])))
    ::Stripe::Webhook.expects(:construct_event).returns(event)

    post webhooks_stripe_path,
      params: payload,
      headers: {"STRIPE-SIGNATURE" => "test_signature"}

    purchase.reload
    assert_equal "failed", purchase.status
  end

  test "stripe webhook handles customer.subscription.created" do
    payload = {
      type: "customer.subscription.created",
      data: {
        object: {
          id: "sub_webhook_test",
          status: "active",
          items: {
            data: [{
              price: {
                unit_amount: 999
              }
            }]
          },
          current_period_end: 1.month.from_now.to_i,
          metadata: {
            access_pass_id: @monthly_pass.id.to_s,
            user_id: @user.id.to_s,
            team_id: @team.id.to_s
          }
        }
      }
    }.to_json

    event_data = JSON.parse(payload)
    event = OpenStruct.new(type: event_data["type"], data: OpenStruct.new(object: OpenStruct.new(event_data["data"]["object"])))
    ::Stripe::Webhook.expects(:construct_event).returns(event)

    assert_difference ["Billing::Purchase.count", "AccessGrant.count"], 1 do
      post webhooks_stripe_path,
        params: payload,
        headers: {"STRIPE-SIGNATURE" => "test_signature"}
    end

    purchase = Billing::Purchase.find_by(stripe_charge_id: "sub_webhook_test")
    assert_not_nil purchase
    assert_equal "completed", purchase.status
  end

  test "stripe webhook handles customer.subscription.deleted" do
    purchase = create(:billing_purchase,
      user: @user,
      team: @team,
      access_pass: @monthly_pass,
      stripe_charge_id: "sub_cancelled_test",
      status: "completed")

    grant = create(:access_grant,
      user: purchase.user,
      team: purchase.team,
      access_pass: purchase.access_pass,
      purchasable: purchase.access_pass.space,
      status: "active")

    payload = {
      type: "customer.subscription.deleted",
      data: {
        object: {
          id: "sub_cancelled_test"
        }
      }
    }.to_json

    event_data = JSON.parse(payload)
    event = OpenStruct.new(type: event_data["type"], data: OpenStruct.new(object: OpenStruct.new(event_data["data"]["object"])))
    ::Stripe::Webhook.expects(:construct_event).returns(event)

    post webhooks_stripe_path,
      params: payload,
      headers: {"STRIPE-SIGNATURE" => "test_signature"}

    purchase.reload
    grant.reload

    assert_equal "cancelled", purchase.status
    assert_equal "cancelled", grant.status
  end

  test "stripe webhook rejects invalid signature" do
    # Create actual Stripe error class instance
    error = ::Stripe::SignatureVerificationError.new("Invalid signature", "sig_header")

    ::Stripe::Webhook.expects(:construct_event).raises(error)

    post webhooks_stripe_path,
      params: {type: "payment_intent.succeeded"}.to_json,
      headers: {"STRIPE-SIGNATURE" => "invalid_signature"}

    assert_response :bad_request
    assert_equal({error: "Invalid signature"}, JSON.parse(response.body).symbolize_keys)
  end

  test "stripe webhook rejects invalid payload" do
    ::Stripe::Webhook.expects(:construct_event).raises(JSON::ParserError)

    post webhooks_stripe_path,
      params: "invalid json",
      headers: {"STRIPE-SIGNATURE" => "test_signature"}

    assert_response :bad_request
    assert_equal({error: "Invalid payload"}, JSON.parse(response.body).symbolize_keys)
  end

  test "stripe webhook ignores unknown event types" do
    payload = {
      type: "unknown.event.type",
      data: {object: {}}
    }.to_json

    event_data = JSON.parse(payload)
    event = OpenStruct.new(type: event_data["type"], data: OpenStruct.new(object: OpenStruct.new(event_data["data"]["object"])))
    ::Stripe::Webhook.expects(:construct_event).returns(event)

    post webhooks_stripe_path,
      params: payload,
      headers: {"STRIPE-SIGNATURE" => "test_signature"}

    assert_response :success
    assert_equal({received: true}, JSON.parse(response.body).symbolize_keys)
  end

  # EDGE CASES

  test "create allows duplicate purchases" do
    # First purchase
    post space_access_pass_purchase_path(@space.slug, @free_pass.slug)

    # Second purchase - creates new purchase and grant (no duplicate prevention)
    assert_difference ["Billing::Purchase.count", "AccessGrant.count"], 1 do
      post space_access_pass_purchase_path(@space.slug, @free_pass.slug)
    end

    # Both purchases should be successful
    assert_redirected_to public_space_path(@space.slug)
  end

  test "create doesn't duplicate team membership" do
    # Create initial membership
    Membership.create!(user: @user, team: @team, role_ids: ["admin"])

    assert_no_difference "Membership.count" do
      post space_access_pass_purchase_path(@space.slug, @free_pass.slug)
    end

    membership = @team.memberships.find_by(user: @user)
    assert_includes membership.role_ids, "admin" # Should keep admin role
  end
end
