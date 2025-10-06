class AccessPass < ApplicationRecord
  include DualIdSupport
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :space, counter_cache: true
  # 🚅 add belongs_to associations above.

  has_many :access_grants, counter_cache: true  # Track who purchased this product
  has_many :buyers, through: :access_grants, source: :user  # Users who bought this
  has_many :access_pass_experiences, dependent: :destroy
  has_many :experiences, through: :access_pass_experiences  # What's included in this pass
  has_many :waitlist_entries, class_name: "AccessPasses::WaitlistEntry", dependent: :destroy
  # 🚅 add has_many associations above.

  has_rich_text :description
  has_one :team, through: :space
  # 🚅 add has_one associations above.

  scope :published, -> { where(published: true) }
  scope :available, -> { published.where("stock_limit IS NULL OR stock_limit > 0") }
  # 🚅 add scopes above.

  validates :name, presence: true
  validates :pricing_type, presence: true
  validates :price_cents, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :slug, presence: true, uniqueness: {scope: :space_id}
  # 🚅 add validations above.

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  after_create :create_stripe_product_and_prices, if: -> { !free? && stripe_product_id.blank? }
  after_update :sync_stripe_prices, if: -> { !free? && saved_change_to_price_cents? }
  # 🚅 add callbacks above.

  delegate :team, to: :space
  # 🚅 add delegations above.

  # Pricing types enum
  enum :pricing_type, {
    free: "free",
    one_time: "one_time",
    monthly: "monthly",
    yearly: "yearly"
  }

  # FriendlyId for URL slugs
  extend FriendlyId
  friendly_id :slug, use: :slugged

  # Monetize price
  monetize :price_cents

  def price_display
    return "Free" if pricing_type == "free" || price_cents.zero?

    price_str = "$#{(price_cents / 100.0).round(2)}"

    case pricing_type
    when "monthly"
      "#{price_str}/month"
    when "yearly"
      "#{price_str}/year"
    else
      price_str
    end
  end

  def recurring?
    %w[monthly yearly].include?(pricing_type)
  end

  def free?
    pricing_type == "free" || price_cents.zero?
  end

  def available?
    published? && (stock_limit.nil? || stock_limit > 0)
  end

  def unlimited_stock?
    stock_limit.nil?
  end

  def stock_remaining
    return nil if unlimited_stock?
    # Account for actual sales by counting active grants
    stock_limit - access_grants.active.count
  end

  def public_url
    "/#{space.slug}/#{slug}"
  end

  # Custom questions management
  def has_custom_questions?
    custom_questions.present? && custom_questions.any?
  end

  def parsed_custom_questions
    return [] if custom_questions.blank?
    custom_questions.is_a?(Array) ? custom_questions : []
  end

  def add_custom_question(question_text, question_type = "text", required = true)
    questions = parsed_custom_questions
    questions << {
      "id" => SecureRandom.uuid,
      "text" => question_text,
      "type" => question_type,
      "required" => required,
      "options" => []
    }
    self.custom_questions = questions
  end

  def remove_custom_question(question_id)
    questions = parsed_custom_questions
    questions.reject! { |q| q["id"] == question_id }
    self.custom_questions = questions
  end

  def waitlist_enabled?
    # For now, waitlist is enabled for all published access passes
    # In the future, this could be a configurable field
    published?
  end

  # Stripe product and price management
  def create_stripe_product_and_prices
    return if Rails.env.test? || free?

    begin
      stripe_service = Billing::StripeService.new

      # Create Stripe product
      product = stripe_service.create_product(
        name: name,
        description: description.to_plain_text.presence || "Access pass for #{space.name}",
        metadata: {
          access_pass_id: id,
          space_id: space_id,
          team_id: team.id
        }
      )

      # Create prices based on pricing type
      case pricing_type
      when "one_time"
        stripe_service.create_price(
          product_id: product.id,
          unit_amount: price_cents,
          currency: "usd"
        )
        update_columns(stripe_product_id: product.id)

      when "monthly"
        monthly_price = stripe_service.create_price(
          product_id: product.id,
          unit_amount: price_cents,
          currency: "usd",
          recurring: {interval: "month"}
        )
        update_columns(
          stripe_product_id: product.id,
          stripe_monthly_price_id: monthly_price.id
        )

      when "yearly"
        yearly_price = stripe_service.create_price(
          product_id: product.id,
          unit_amount: price_cents,
          currency: "usd",
          recurring: {interval: "year"}
        )
        update_columns(
          stripe_product_id: product.id,
          stripe_yearly_price_id: yearly_price.id
        )
      end

      Rails.logger.info "✅ Stripe product/prices created for AccessPass ##{id}"
    rescue Stripe::StripeError => e
      Rails.logger.error "❌ Failed to create Stripe product for AccessPass ##{id}: #{e.message}"
      # Don't raise - allow AccessPass to be created even if Stripe sync fails
    end
  end

  def sync_stripe_prices
    return if Rails.env.test? || free? || stripe_product_id.blank?

    begin
      stripe_service = Billing::StripeService.new

      # Stripe prices are immutable, so create new ones when price changes
      case pricing_type
      when "one_time"
        # For one-time, we can just use the product directly with new price
        # Stripe will handle this in the checkout session

      when "monthly"
        new_price = stripe_service.create_price(
          product_id: stripe_product_id,
          unit_amount: price_cents,
          currency: "usd",
          recurring: {interval: "month"}
        )
        update_column(:stripe_monthly_price_id, new_price.id)

      when "yearly"
        new_price = stripe_service.create_price(
          product_id: stripe_product_id,
          unit_amount: price_cents,
          currency: "usd",
          recurring: {interval: "year"}
        )
        update_column(:stripe_yearly_price_id, new_price.id)
      end

      Rails.logger.info "✅ Stripe prices updated for AccessPass ##{id}"
    rescue Stripe::StripeError => e
      Rails.logger.error "❌ Failed to sync Stripe prices for AccessPass ##{id}: #{e.message}"
    end
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
  # 🚅 add methods above.
end
