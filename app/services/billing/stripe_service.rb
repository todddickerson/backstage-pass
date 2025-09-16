module Billing
  class StripeService
    def initialize
      Stripe.api_key = ENV['STRIPE_SECRET_KEY'] || Rails.application.credentials.dig(:stripe, :secret_key)
    end

    def create_payment_intent(amount:, currency: 'usd', payment_method: nil, customer: nil, metadata: {})
      params = {
        amount: amount,
        currency: currency,
        customer: customer,
        metadata: metadata
      }
      
      if payment_method
        params[:payment_method] = payment_method
        params[:confirm] = true
      else
        params[:automatic_payment_methods] = { enabled: true }
      end
      
      Stripe::PaymentIntent.create(params)
    end

    def confirm_payment_intent(payment_intent_id)
      Stripe::PaymentIntent.confirm(payment_intent_id)
    end

    def create_subscription(customer:, items:, payment_method: nil, metadata: {})
      params = {
        customer: customer,
        items: items,
        metadata: metadata,
        payment_behavior: 'default_incomplete',
        payment_settings: { save_default_payment_method: 'on_subscription' },
        expand: ['latest_invoice.payment_intent']
      }

      params[:default_payment_method] = payment_method if payment_method.present?

      Stripe::Subscription.create(params)
    end

    def cancel_subscription(subscription_id, at_period_end: true)
      if at_period_end
        Stripe::Subscription.update(subscription_id, { cancel_at_period_end: true })
      else
        Stripe::Subscription.cancel(subscription_id)
      end
    end

    def create_customer(email:, name: nil, metadata: {})
      Stripe::Customer.create(
        email: email,
        name: name,
        metadata: metadata
      )
    end

    def attach_payment_method(payment_method_id:, customer_id:)
      payment_method = Stripe::PaymentMethod.attach(
        payment_method_id,
        { customer: customer_id }
      )
      
      # Set as default payment method
      Stripe::Customer.update(
        customer_id,
        { invoice_settings: { default_payment_method: payment_method_id } }
      )
      
      payment_method
    end

    def create_setup_intent(customer: nil, metadata: {})
      Stripe::SetupIntent.create(
        customer: customer,
        metadata: metadata,
        automatic_payment_methods: { enabled: true }
      )
    end

    def create_product(name:, description: nil, metadata: {})
      Stripe::Product.create(
        name: name,
        description: description,
        metadata: metadata
      )
    end

    def create_price(product_id:, unit_amount:, currency: 'usd', recurring: nil)
      params = {
        product: product_id,
        unit_amount: unit_amount,
        currency: currency
      }

      params[:recurring] = recurring if recurring.present?

      Stripe::Price.create(params)
    end

    def retrieve_payment_intent(payment_intent_id)
      Stripe::PaymentIntent.retrieve(payment_intent_id)
    end

    def retrieve_subscription(subscription_id)
      Stripe::Subscription.retrieve(subscription_id)
    end
  end
end