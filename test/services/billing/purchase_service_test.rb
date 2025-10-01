require "test_helper"

module Billing
  class PurchaseServiceTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @team = create(:team)
      @space = create(:space, team: @team)
      @free_pass = create(:access_pass, space: @space, name: "Free Pass", pricing_type: "free", price_cents: 0)
      @one_time_pass = create(:access_pass, space: @space, name: "One-Time Pass", pricing_type: "one_time", price_cents: 2999)
      @monthly_pass = create(:access_pass, space: @space, name: "Monthly Pass", pricing_type: "monthly", price_cents: 1999, stripe_monthly_price_id: "price_monthly_test")
      @yearly_pass = create(:access_pass, space: @space, name: "Yearly Pass", pricing_type: "yearly", price_cents: 19999, stripe_yearly_price_id: "price_yearly_test")
    end

    # FREE PURCHASE TESTS

    test "execute processes free access pass successfully" do
      service = PurchaseService.new(user: @user, access_pass: @free_pass)

      result = nil
      assert_difference ["Purchase.count", "AccessGrant.count", "Membership.count"], 1 do
        result = service.execute
      end

      assert result[:success]
      assert_not_nil result[:purchase]
      assert_not_nil result[:access_grant]

      purchase = result[:purchase]
      assert_equal 0, purchase.amount_cents
      assert_equal "completed", purchase.status
      assert_equal @user, purchase.user
      assert_equal @team, purchase.team
      assert_equal @free_pass, purchase.access_pass

      grant = result[:access_grant]
      assert_equal "active", grant.status
      assert_equal @space, grant.purchasable
      assert_nil grant.expires_at
    end

    test "execute adds buyer to team for free pass" do
      service = PurchaseService.new(user: @user, access_pass: @free_pass)

      service.execute

      membership = @team.memberships.find_by(user: @user)
      assert_not_nil membership
      assert_includes membership.role_ids, "buyer"
      assert_equal "access_pass", membership.source  # AccessGrant callback sets this
    end

    test "execute doesn't create duplicate membership for free pass" do
      # Create existing membership with different role
      Membership.create!(user: @user, team: @team, role_ids: ["admin"])

      service = PurchaseService.new(user: @user, access_pass: @free_pass)

      assert_no_difference "Membership.count" do
        service.execute
      end

      membership = @team.memberships.find_by(user: @user)
      assert_includes membership.role_ids, "admin" # Keeps existing role
    end

    test "execute handles errors for free pass" do
      # Force an error by making access_pass nil
      service = PurchaseService.new(user: @user, access_pass: nil)

      result = service.execute

      assert_not result[:success]
      assert_not_nil result[:error]
    end

    # ONE-TIME PURCHASE TESTS

    test "execute processes one-time purchase successfully" do
      # Mock Stripe customer creation
      customer = OpenStruct.new(id: "cus_test_123")
      ::Stripe::Customer.expects(:create).returns(customer)

      # Mock payment intent creation
      payment_intent = OpenStruct.new(
        id: "pi_test_123",
        status: "requires_confirmation"
      )

      # Mock payment intent confirmation
      confirmed_intent = OpenStruct.new(
        id: "pi_test_123",
        status: "succeeded"
      )

      stripe_service = mock("stripe_service")
      StripeService.expects(:new).returns(stripe_service).once
      stripe_service.expects(:create_payment_intent).with(
        amount: 2999,
        currency: "usd",
        payment_method: "pm_test_123",
        customer: "cus_test_123",
        metadata: {
          access_pass_id: @one_time_pass.id,
          user_id: @user.id,
          team_id: @team.id
        }
      ).returns(payment_intent)

      stripe_service.expects(:confirm_payment_intent).with("pi_test_123").returns(confirmed_intent)

      service = PurchaseService.new(
        user: @user,
        access_pass: @one_time_pass,
        payment_method_id: "pm_test_123"
      )

      result = nil
      assert_difference ["Purchase.count", "AccessGrant.count"], 1 do
        result = service.execute
      end

      assert result[:success]

      purchase = result[:purchase]
      assert_equal "completed", purchase.status
      assert_equal 2999, purchase.amount_cents
      assert_equal "pi_test_123", purchase.stripe_payment_intent_id

      grant = result[:access_grant]
      assert_equal "active", grant.status
      assert_nil grant.expires_at # One-time purchases don't expire
    end

    test "execute handles failed one-time payment" do
      customer = OpenStruct.new(id: "cus_test")
      ::Stripe::Customer.expects(:create).returns(customer)

      failed_intent = OpenStruct.new(
        id: "pi_failed",
        status: "requires_payment_method"
      )

      stripe_service = mock("stripe_service")
      StripeService.expects(:new).returns(stripe_service).once
      stripe_service.expects(:create_payment_intent).returns(failed_intent)
      stripe_service.expects(:confirm_payment_intent).returns(failed_intent)

      service = PurchaseService.new(
        user: @user,
        access_pass: @one_time_pass,
        payment_method_id: "pm_declined"
      )

      result = nil
      assert_difference "Purchase.count", 1 do
        assert_no_difference "AccessGrant.count" do
          result = service.execute
        end
      end

      assert_not result[:success]
      assert_equal "Payment failed", result[:error]

      purchase = Purchase.last
      assert_equal "failed", purchase.status
    end

    test "execute handles Stripe card error" do
      ::Stripe::Customer.expects(:create).raises(
        ::Stripe::CardError.new("Card declined", "card_declined")
      )

      service = PurchaseService.new(
        user: @user,
        access_pass: @one_time_pass,
        payment_method_id: "pm_declined"
      )

      result = service.execute

      assert_not result[:success]
      assert_equal "Card declined", result[:error]
    end

    test "execute reuses existing Stripe customer" do
      @user.update!(stripe_customer_id: "cus_existing_123")

      payment_intent = OpenStruct.new(id: "pi_test", status: "requires_confirmation")
      confirmed_intent = OpenStruct.new(id: "pi_test", status: "succeeded")

      stripe_service = mock("stripe_service")
      StripeService.expects(:new).returns(stripe_service).once

      # Should not create a new customer
      ::Stripe::Customer.expects(:create).never

      stripe_service.expects(:create_payment_intent).with(
        amount: 2999,
        currency: "usd",
        payment_method: "pm_test",
        customer: "cus_existing_123",
        metadata: {
          access_pass_id: @one_time_pass.id,
          user_id: @user.id,
          team_id: @team.id
        }
      ).returns(payment_intent)

      stripe_service.expects(:confirm_payment_intent).returns(confirmed_intent)

      service = PurchaseService.new(
        user: @user,
        access_pass: @one_time_pass,
        payment_method_id: "pm_test"
      )

      result = service.execute
      assert result[:success]
    end

    # SUBSCRIPTION TESTS

    test "execute processes monthly subscription successfully" do
      customer = OpenStruct.new(id: "cus_test")
      ::Stripe::Customer.expects(:create).returns(customer)

      subscription = OpenStruct.new(
        id: "sub_test_123",
        status: "active",
        current_period_end: 1.month.from_now.to_i
      )

      stripe_service = mock("stripe_service")
      StripeService.expects(:new).returns(stripe_service)

      stripe_service.expects(:create_subscription).with(
        customer: "cus_test",
        items: [{price: "price_monthly_test"}],
        payment_method: "pm_test",
        metadata: {
          access_pass_id: @monthly_pass.id,
          user_id: @user.id,
          team_id: @team.id
        }
      ).returns(subscription)

      service = PurchaseService.new(
        user: @user,
        access_pass: @monthly_pass,
        payment_method_id: "pm_test"
      )

      result = nil
      assert_difference ["Purchase.count", "AccessGrant.count"], 1 do
        result = service.execute
      end

      assert result[:success]

      purchase = result[:purchase]
      assert_equal "completed", purchase.status
      assert_equal "sub_test_123", purchase.stripe_charge_id

      grant = result[:access_grant]
      assert_not_nil grant.expires_at
      assert grant.expires_at > Time.current
      assert grant.expires_at <= 1.month.from_now + 1.minute
    end

    test "execute processes yearly subscription successfully" do
      customer = OpenStruct.new(id: "cus_test")
      ::Stripe::Customer.expects(:create).returns(customer)

      subscription = OpenStruct.new(
        id: "sub_yearly_test",
        status: "active",
        current_period_end: 1.year.from_now.to_i
      )

      stripe_service = mock("stripe_service")
      StripeService.expects(:new).returns(stripe_service)

      stripe_service.expects(:create_subscription).with(
        customer: "cus_test",
        items: [{price: "price_yearly_test"}],
        payment_method: "pm_test",
        metadata: {
          access_pass_id: @yearly_pass.id,
          user_id: @user.id,
          team_id: @team.id
        }
      ).returns(subscription)

      service = PurchaseService.new(
        user: @user,
        access_pass: @yearly_pass,
        payment_method_id: "pm_test"
      )

      result = service.execute

      assert result[:success]

      grant = result[:access_grant]
      assert grant.expires_at > 11.months.from_now
      assert grant.expires_at <= 13.months.from_now
    end

    test "execute handles incomplete subscription" do
      customer = OpenStruct.new(id: "cus_test")
      ::Stripe::Customer.expects(:create).returns(customer)

      subscription = OpenStruct.new(
        id: "sub_incomplete",
        status: "incomplete"
      )

      stripe_service = mock("stripe_service")
      StripeService.expects(:new).returns(stripe_service)
      stripe_service.expects(:create_subscription).returns(subscription)

      service = PurchaseService.new(
        user: @user,
        access_pass: @monthly_pass,
        payment_method_id: "pm_test"
      )

      result = nil
      assert_difference "Purchase.count", 1 do
        assert_no_difference "AccessGrant.count" do
          result = service.execute
        end
      end

      assert_not result[:success]
      assert_equal "Subscription requires payment method", result[:error]

      purchase = Purchase.last
      assert_equal "pending", purchase.status
    end

    test "execute handles subscription Stripe error" do
      ::Stripe::Customer.expects(:create).raises(
        ::Stripe::APIConnectionError.new("Network error")
      )

      service = PurchaseService.new(
        user: @user,
        access_pass: @monthly_pass,
        payment_method_id: "pm_test"
      )

      result = service.execute

      assert_not result[:success]
      assert_equal "Network error", result[:error]
    end

    # HELPER METHOD TESTS

    test "calculate_expiration_date returns nil for free passes" do
      service = PurchaseService.new(user: @user, access_pass: @free_pass)
      assert_nil service.send(:calculate_expiration_date)
    end

    test "calculate_expiration_date returns nil for one-time passes" do
      service = PurchaseService.new(user: @user, access_pass: @one_time_pass)
      assert_nil service.send(:calculate_expiration_date)
    end

    test "calculate_expiration_date returns 1 month for monthly passes" do
      service = PurchaseService.new(user: @user, access_pass: @monthly_pass)
      expiration = service.send(:calculate_expiration_date)

      assert_not_nil expiration
      assert expiration > 29.days.from_now
      assert expiration <= 31.days.from_now
    end

    test "calculate_expiration_date returns 1 year for yearly passes" do
      service = PurchaseService.new(user: @user, access_pass: @yearly_pass)
      expiration = service.send(:calculate_expiration_date)

      assert_not_nil expiration
      assert expiration > 364.days.from_now
      assert expiration <= 366.days.from_now
    end

    test "team method returns correct team from access_pass" do
      service = PurchaseService.new(user: @user, access_pass: @free_pass)
      assert_equal @team, service.send(:team)
    end

    test "ensure_stripe_customer creates new customer when needed" do
      assert_nil @user.stripe_customer_id

      customer = OpenStruct.new(
        id: "cus_new_123",
        email: @user.email
      )
      ::Stripe::Customer.expects(:create).with(
        email: @user.email,
        name: @user.full_name,
        metadata: {user_id: @user.id}
      ).returns(customer)

      service = PurchaseService.new(user: @user, access_pass: @free_pass)
      customer_id = service.send(:ensure_stripe_customer)

      assert_equal "cus_new_123", customer_id

      @user.reload
      assert_equal "cus_new_123", @user.stripe_customer_id
    end

    test "ensure_stripe_customer returns existing customer ID" do
      @user.update!(stripe_customer_id: "cus_existing")

      ::Stripe::Customer.expects(:create).never

      service = PurchaseService.new(user: @user, access_pass: @free_pass)
      customer_id = service.send(:ensure_stripe_customer)

      assert_equal "cus_existing", customer_id
    end
  end
end
