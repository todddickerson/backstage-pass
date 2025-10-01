require "test_helper"

module Billing
  class StripeServiceTest < ActiveSupport::TestCase
    include Mocha::ParameterMatchers
    setup do
      @service = StripeService.new
    end

    # INITIALIZATION TEST

    test "initialize sets Stripe API key from ENV" do
      # The service should set Stripe.api_key on initialization
      assert_not_nil ::Stripe.api_key
    end

    # PAYMENT INTENT TESTS

    test "create_payment_intent creates payment intent with required params" do
      payment_intent = OpenStruct.new(
        id: "pi_test_123",
        amount: 1000,
        currency: "usd"
      )

      ::Stripe::PaymentIntent.expects(:create).with(
        amount: 1000,
        currency: "usd",
        customer: nil,
        metadata: {},
        automatic_payment_methods: {enabled: true}
      ).returns(payment_intent)

      result = @service.create_payment_intent(amount: 1000)

      assert_equal "pi_test_123", result.id
      assert_equal 1000, result.amount
    end

    test "create_payment_intent with payment method sets confirm flag" do
      payment_intent = OpenStruct.new(
        id: "pi_confirmed",
        amount: 2000,
        currency: "usd",
        status: "succeeded"
      )

      ::Stripe::PaymentIntent.expects(:create).with(
        amount: 2000,
        currency: "usd",
        customer: "cus_test",
        metadata: {order_id: "123"},
        payment_method: "pm_test",
        confirm: true
      ).returns(payment_intent)

      result = @service.create_payment_intent(
        amount: 2000,
        customer: "cus_test",
        payment_method: "pm_test",
        metadata: {order_id: "123"}
      )

      assert_equal "pi_confirmed", result.id
    end

    test "create_payment_intent allows custom currency" do
      payment_intent = OpenStruct.new(id: "pi_eur", currency: "eur")

      ::Stripe::PaymentIntent.expects(:create).with(
        {amount: 1000, currency: "eur", customer: nil, metadata: {}, automatic_payment_methods: {enabled: true}}
      ).returns(payment_intent)

      result = @service.create_payment_intent(amount: 1000, currency: "eur")

      assert_equal "eur", result.currency
    end

    test "confirm_payment_intent confirms existing intent" do
      confirmed_intent = OpenStruct.new(
        id: "pi_to_confirm",
        status: "succeeded"
      )

      ::Stripe::PaymentIntent.expects(:confirm).with("pi_to_confirm").returns(confirmed_intent)

      result = @service.confirm_payment_intent("pi_to_confirm")

      assert_equal "pi_to_confirm", result.id
      assert_equal "succeeded", result.status
    end

    test "retrieve_payment_intent retrieves existing intent" do
      intent = OpenStruct.new(id: "pi_retrieve")

      ::Stripe::PaymentIntent.expects(:retrieve).with("pi_retrieve").returns(intent)

      result = @service.retrieve_payment_intent("pi_retrieve")

      assert_equal "pi_retrieve", result.id
    end

    # SUBSCRIPTION TESTS

    test "create_subscription creates subscription with required params" do
      subscription = OpenStruct.new(
        id: "sub_test",
        status: "active"
      )

      ::Stripe::Subscription.expects(:create).with(
        customer: "cus_test",
        items: [{price: "price_123"}],
        metadata: {},
        payment_behavior: "default_incomplete",
        payment_settings: {save_default_payment_method: "on_subscription"},
        expand: ["latest_invoice.payment_intent"]
      ).returns(subscription)

      result = @service.create_subscription(
        customer: "cus_test",
        items: [{price: "price_123"}]
      )

      assert_equal "sub_test", result.id
    end

    test "create_subscription with payment method includes default_payment_method" do
      subscription = OpenStruct.new(id: "sub_with_pm")

      ::Stripe::Subscription.expects(:create).with(
        {customer: "cus_test", items: [{price: "price_123"}], metadata: {}, payment_behavior: "default_incomplete", payment_settings: {save_default_payment_method: "on_subscription"}, expand: ["latest_invoice.payment_intent"], default_payment_method: "pm_test"}
      ).returns(subscription)

      result = @service.create_subscription(
        customer: "cus_test",
        items: [{price: "price_123"}],
        payment_method: "pm_test"
      )

      assert_equal "sub_with_pm", result.id
    end

    test "create_subscription includes metadata" do
      subscription = OpenStruct.new(id: "sub_metadata")

      ::Stripe::Subscription.expects(:create).with(
        {customer: "cus_test", items: [{price: "price_123"}], metadata: {user_id: "456", plan: "premium"}, payment_behavior: "default_incomplete", payment_settings: {save_default_payment_method: "on_subscription"}, expand: ["latest_invoice.payment_intent"]}
      ).returns(subscription)

      result = @service.create_subscription(
        customer: "cus_test",
        items: [{price: "price_123"}],
        metadata: {user_id: "456", plan: "premium"}
      )

      assert_equal "sub_metadata", result.id
    end

    test "cancel_subscription cancels at period end by default" do
      subscription = OpenStruct.new(
        id: "sub_to_cancel",
        cancel_at_period_end: true
      )

      ::Stripe::Subscription.expects(:update).with(
        "sub_to_cancel",
        {cancel_at_period_end: true}
      ).returns(subscription)

      result = @service.cancel_subscription("sub_to_cancel")

      assert result.cancel_at_period_end
    end

    test "cancel_subscription cancels immediately when requested" do
      subscription = OpenStruct.new(
        id: "sub_cancel_now",
        status: "canceled"
      )

      ::Stripe::Subscription.expects(:cancel).with("sub_cancel_now").returns(subscription)

      result = @service.cancel_subscription("sub_cancel_now", at_period_end: false)

      assert_equal "canceled", result.status
    end

    test "retrieve_subscription retrieves existing subscription" do
      subscription = OpenStruct.new(id: "sub_retrieve")

      ::Stripe::Subscription.expects(:retrieve).with("sub_retrieve").returns(subscription)

      result = @service.retrieve_subscription("sub_retrieve")

      assert_equal "sub_retrieve", result.id
    end

    # CUSTOMER TESTS

    test "create_customer creates customer with email" do
      customer = OpenStruct.new(
        id: "cus_new",
        email: "test@example.com"
      )

      ::Stripe::Customer.expects(:create).with(
        email: "test@example.com",
        name: nil,
        metadata: {}
      ).returns(customer)

      result = @service.create_customer(email: "test@example.com")

      assert_equal "cus_new", result.id
      assert_equal "test@example.com", result.email
    end

    test "create_customer with name and metadata" do
      customer = OpenStruct.new(id: "cus_full")

      ::Stripe::Customer.expects(:create).with(
        email: "test@example.com",
        name: "John Doe",
        metadata: {user_id: "789"}
      ).returns(customer)

      result = @service.create_customer(
        email: "test@example.com",
        name: "John Doe",
        metadata: {user_id: "789"}
      )

      assert_equal "cus_full", result.id
    end

    # PAYMENT METHOD TESTS

    test "attach_payment_method attaches and sets as default" do
      payment_method = OpenStruct.new(
        id: "pm_attach",
        customer: "cus_test"
      )

      customer = OpenStruct.new(id: "cus_test")

      ::Stripe::PaymentMethod.expects(:attach).with(
        "pm_attach",
        {customer: "cus_test"}
      ).returns(payment_method)

      ::Stripe::Customer.expects(:update).with(
        "cus_test",
        {invoice_settings: {default_payment_method: "pm_attach"}}
      ).returns(customer)

      result = @service.attach_payment_method(
        payment_method_id: "pm_attach",
        customer_id: "cus_test"
      )

      assert_equal "pm_attach", result.id
    end

    # SETUP INTENT TESTS

    test "create_setup_intent creates setup intent for customer" do
      setup_intent = OpenStruct.new(
        id: "seti_test",
        customer: "cus_test",
        client_secret: "seti_secret_123"
      )

      ::Stripe::SetupIntent.expects(:create).with(
        customer: "cus_test",
        metadata: {access_pass_id: "123"},
        automatic_payment_methods: {enabled: true}
      ).returns(setup_intent)

      result = @service.create_setup_intent(
        customer: "cus_test",
        metadata: {access_pass_id: "123"}
      )

      assert_equal "seti_test", result.id
      assert_equal "cus_test", result.customer
    end

    test "create_setup_intent without customer" do
      setup_intent = OpenStruct.new(id: "seti_no_cus")

      ::Stripe::SetupIntent.expects(:create).with(
        customer: nil,
        metadata: {},
        automatic_payment_methods: {enabled: true}
      ).returns(setup_intent)

      result = @service.create_setup_intent

      assert_equal "seti_no_cus", result.id
    end

    # PRODUCT AND PRICE TESTS

    test "create_product creates Stripe product" do
      product = OpenStruct.new(
        id: "prod_test",
        name: "Premium Access"
      )

      ::Stripe::Product.expects(:create).with(
        name: "Premium Access",
        description: "Full platform access",
        metadata: {access_pass_id: "456"}
      ).returns(product)

      result = @service.create_product(
        name: "Premium Access",
        description: "Full platform access",
        metadata: {access_pass_id: "456"}
      )

      assert_equal "prod_test", result.id
      assert_equal "Premium Access", result.name
    end

    test "create_price creates one-time price" do
      price = OpenStruct.new(
        id: "price_onetime",
        unit_amount: 2999,
        currency: "usd"
      )

      ::Stripe::Price.expects(:create).with(
        product: "prod_test",
        unit_amount: 2999,
        currency: "usd"
      ).returns(price)

      result = @service.create_price(
        product_id: "prod_test",
        unit_amount: 2999
      )

      assert_equal "price_onetime", result.id
      assert_equal 2999, result.unit_amount
    end

    test "create_price creates recurring price" do
      price = OpenStruct.new(
        id: "price_monthly",
        recurring: {interval: "month"}
      )

      ::Stripe::Price.expects(:create).with(
        product: "prod_test",
        unit_amount: 999,
        currency: "usd",
        recurring: {interval: "month"}
      ).returns(price)

      result = @service.create_price(
        product_id: "prod_test",
        unit_amount: 999,
        recurring: {interval: "month"}
      )

      assert_equal "price_monthly", result.id
    end

    test "create_price with custom currency" do
      price = OpenStruct.new(id: "price_eur", currency: "eur")

      ::Stripe::Price.expects(:create).with(
        {product: "prod_test", unit_amount: 1000, currency: "eur"}
      ).returns(price)

      result = @service.create_price(
        product_id: "prod_test",
        unit_amount: 1000,
        currency: "eur"
      )

      assert_equal "eur", result.currency
    end

    # ERROR HANDLING TESTS

    test "handles Stripe::CardError gracefully" do
      ::Stripe::PaymentIntent.expects(:create).raises(
        ::Stripe::CardError.new("Card declined", "card_declined")
      )

      assert_raises(::Stripe::CardError) do
        @service.create_payment_intent(amount: 1000)
      end
    end

    test "handles Stripe::APIError gracefully" do
      ::Stripe::Customer.expects(:create).raises(
        ::Stripe::APIError.new("API error")
      )

      assert_raises(::Stripe::APIError) do
        @service.create_customer(email: "test@example.com")
      end
    end

    test "handles Stripe::APIConnectionError gracefully" do
      ::Stripe::Subscription.expects(:create).raises(
        ::Stripe::APIConnectionError.new("Network error")
      )

      assert_raises(::Stripe::APIConnectionError) do
        @service.create_subscription(customer: "cus_test", items: [{price: "price_123"}])
      end
    end
  end
end
