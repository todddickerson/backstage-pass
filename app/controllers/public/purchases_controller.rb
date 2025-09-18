class Public::PurchasesController < Public::ApplicationController
  before_action :authenticate_user!
  before_action :load_access_pass

  # GET /spaces/:space_slug/:access_pass_slug/purchase
  def new
    @purchase = Billing::Purchase.new
    @stripe_publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"] || Rails.application.credentials.dig(:stripe, :publishable_key)

    # Create a Setup Intent for collecting payment method
    if @access_pass.pricing_type != "free"
      stripe_service = Billing::StripeService.new
      @setup_intent = stripe_service.create_setup_intent(
        customer: ensure_stripe_customer,
        metadata: {
          access_pass_id: @access_pass.id,
          user_id: current_user.id
        }
      )
    end
  end

  # POST /spaces/:space_slug/:access_pass_slug/purchase
  def create
    service = Billing::PurchaseService.new(
      user: current_user,
      access_pass: @access_pass,
      payment_method_id: params[:payment_method_id],
      payment_intent_id: params[:payment_intent_id]
    )

    result = service.execute

    if result[:success]
      redirect_to public_space_path(@access_pass.space.slug), notice: t("purchases.success")
    else
      flash[:alert] = result[:error] || t("purchases.failed")
      redirect_to new_space_access_pass_purchase_path(@access_pass.space.slug, @access_pass.slug)
    end
  end

  # POST /purchases/stripe-webhook
  def stripe_webhook
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"] || Rails.application.credentials.dig(:stripe, :webhook_secret)

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      render json: {error: "Invalid payload"}, status: 400 and return
    rescue Stripe::SignatureVerificationError
      render json: {error: "Invalid signature"}, status: 400 and return
    end

    case event["type"]
    when "payment_intent.succeeded"
      handle_payment_intent_succeeded(event["data"]["object"])
    when "payment_intent.payment_failed"
      handle_payment_intent_failed(event["data"]["object"])
    when "customer.subscription.created"
      handle_subscription_created(event["data"]["object"])
    when "customer.subscription.deleted"
      handle_subscription_deleted(event["data"]["object"])
    when "customer.subscription.updated"
      handle_subscription_updated(event["data"]["object"])
    end

    render json: {received: true}
  end

  private

  def load_access_pass
    @space = Space.published.friendly.find(params[:space_slug])
    @access_pass = @space.access_passes.find_by!(slug: params[:access_pass_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("access_passes.not_found")
  end

  def ensure_stripe_customer
    return current_user.stripe_customer_id if current_user.stripe_customer_id.present?

    stripe_service = Billing::StripeService.new
    customer = stripe_service.create_customer(
      email: current_user.email,
      name: current_user.full_name,
      metadata: {user_id: current_user.id}
    )

    current_user.update!(stripe_customer_id: customer.id)
    customer.id
  end

  def handle_payment_intent_succeeded(payment_intent)
    purchase = Billing::Purchase.find_by(stripe_payment_intent_id: payment_intent["id"])
    return unless purchase

    purchase.update!(status: "completed")

    # Create or update access grant
    AccessGrant.find_or_create_by(
      user: purchase.user,
      access_pass: purchase.access_pass,
      team: purchase.team
    ) do |grant|
      grant.purchasable = purchase.access_pass.space
      grant.status = "active"
    end

    # Send confirmation email
    PurchaseMailer.confirmation(purchase).deliver_later
  end

  def handle_payment_intent_failed(payment_intent)
    purchase = Billing::Purchase.find_by(stripe_payment_intent_id: payment_intent["id"])
    return unless purchase

    purchase.update!(status: "failed")
  end

  def handle_subscription_created(subscription)
    metadata = subscription["metadata"]
    return unless metadata["access_pass_id"]

    access_pass = AccessPass.find(metadata["access_pass_id"])
    user = User.find(metadata["user_id"])
    team = Team.find(metadata["team_id"])

    Billing::Purchase.find_or_create_by(
      stripe_charge_id: subscription["id"]
    ) do |p|
      p.user = user
      p.team = team
      p.access_pass = access_pass
      p.amount_cents = subscription["items"]["data"][0]["price"]["unit_amount"]
      p.status = "completed"
    end

    # Create or update access grant
    AccessGrant.find_or_create_by(
      user: user,
      access_pass: access_pass,
      team: team
    ) do |grant|
      grant.purchasable = access_pass.space
      grant.status = "active"
      grant.expires_at = Time.at(subscription["current_period_end"])
    end
  end

  def handle_subscription_deleted(subscription)
    purchase = Billing::Purchase.find_by(stripe_charge_id: subscription["id"])
    return unless purchase

    purchase.update!(status: "cancelled")

    # Deactivate access grant
    access_grant = AccessGrant.find_by(
      user: purchase.user,
      access_pass: purchase.access_pass
    )
    access_grant&.update!(status: "cancelled")
  end

  def handle_subscription_updated(subscription)
    purchase = Billing::Purchase.find_by(stripe_charge_id: subscription["id"])
    return unless purchase

    # Update access grant expiration
    access_grant = AccessGrant.find_by(
      user: purchase.user,
      access_pass: purchase.access_pass
    )

    if access_grant && subscription["status"] == "active"
      access_grant.update!(
        expires_at: Time.at(subscription["current_period_end"]),
        status: "active"
      )
    end
  end
end
