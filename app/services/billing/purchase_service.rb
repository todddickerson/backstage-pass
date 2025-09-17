module Billing
  class PurchaseService
    include ActiveModel::Model

    attr_accessor :user, :access_pass, :payment_method_id, :payment_intent_id

    def initialize(user:, access_pass:, payment_method_id: nil, payment_intent_id: nil)
      @user = user
      @access_pass = access_pass
      @payment_method_id = payment_method_id
      @payment_intent_id = payment_intent_id
    end

    def execute
      return handle_free_purchase if access_pass.pricing_type == "free"
      return handle_one_time_purchase if access_pass.pricing_type == "one_time"
      handle_subscription_purchase
    end

    private

    def handle_free_purchase
      ActiveRecord::Base.transaction do
        # Create the purchase record
        purchase = create_purchase(
          amount_cents: 0,
          status: "completed"
        )

        # Create the access grant
        access_grant = create_access_grant(purchase)

        # Add buyer as team member
        add_buyer_to_team

        {success: true, purchase: purchase, access_grant: access_grant}
      end
    rescue => e
      {success: false, error: e.message}
    end

    def handle_one_time_purchase
      ActiveRecord::Base.transaction do
        # Create Stripe payment intent
        stripe_service = StripeService.new
        payment_intent = stripe_service.create_payment_intent(
          amount: access_pass.price_cents,
          currency: "usd",
          payment_method: payment_method_id,
          customer: ensure_stripe_customer,
          metadata: {
            access_pass_id: access_pass.id,
            user_id: user.id,
            team_id: team.id
          }
        )

        # Create purchase record
        purchase = create_purchase(
          amount_cents: access_pass.price_cents,
          stripe_payment_intent_id: payment_intent.id,
          status: "pending"
        )

        # Confirm the payment
        confirmed_intent = stripe_service.confirm_payment_intent(payment_intent.id)

        if confirmed_intent.status == "succeeded"
          # Update purchase status
          purchase.update!(status: "completed")

          # Create access grant
          access_grant = create_access_grant(purchase)

          # Add buyer to team
          add_buyer_to_team

          {success: true, purchase: purchase, access_grant: access_grant}
        else
          purchase.update!(status: "failed")
          {success: false, error: "Payment failed"}
        end
      end
    rescue Stripe::Error => e
      {success: false, error: e.message}
    end

    def handle_subscription_purchase
      ActiveRecord::Base.transaction do
        # Create Stripe subscription
        stripe_service = StripeService.new

        # Determine price based on pricing type
        price_id = case access_pass.pricing_type
        when "monthly"
          access_pass.stripe_monthly_price_id
        when "yearly"
          access_pass.stripe_yearly_price_id
        end

        subscription = stripe_service.create_subscription(
          customer: ensure_stripe_customer,
          items: [{price: price_id}],
          payment_method: payment_method_id,
          metadata: {
            access_pass_id: access_pass.id,
            user_id: user.id,
            team_id: team.id
          }
        )

        # Create purchase record
        purchase = create_purchase(
          amount_cents: access_pass.price_cents,
          stripe_charge_id: subscription.id,
          status: (subscription.status == "active") ? "completed" : "pending"
        )

        if subscription.status == "active"
          # Create access grant
          access_grant = create_access_grant(purchase)

          # Add buyer to team
          add_buyer_to_team

          {success: true, purchase: purchase, access_grant: access_grant, subscription: subscription}
        else
          {success: false, error: "Subscription requires payment method", subscription: subscription}
        end
      end
    rescue Stripe::Error => e
      {success: false, error: e.message}
    end

    def create_purchase(attributes = {})
      Billing::Purchase.create!(
        team: team,
        user: user,
        access_pass: access_pass,
        **attributes
      )
    end

    def create_access_grant(purchase)
      AccessGrant.create!(
        team: team,
        user: user,
        access_pass: access_pass,
        purchasable: access_pass.space,
        status: "active",
        expires_at: calculate_expiration_date
      )
    end

    def add_buyer_to_team
      # Check if user is already a member of this team
      existing_membership = user.memberships.find_by(team: team)

      if existing_membership.nil?
        # Create new membership with buyer role
        Membership.create!(
          user: user,
          team: team,
          role_ids: ["buyer"],
          source: "purchase"
        )
      elsif !existing_membership.buyer?
        # Don't change existing members' roles if they're already admin/editor/viewer
        # They already have higher permissions than buyer
      end
    end

    def ensure_stripe_customer
      # Get or create Stripe customer for user
      return user.stripe_customer_id if user.stripe_customer_id.present?

      customer = Stripe::Customer.create(
        email: user.email,
        name: user.full_name,
        metadata: {user_id: user.id}
      )

      user.update!(stripe_customer_id: customer.id)
      customer.id
    end

    def calculate_expiration_date
      case access_pass.pricing_type
      when "free", "one_time"
        nil # No expiration for free or one-time purchases
      when "monthly"
        1.month.from_now
      when "yearly"
        1.year.from_now
      end
    end

    def team
      @team ||= access_pass.space.team
    end
  end
end
