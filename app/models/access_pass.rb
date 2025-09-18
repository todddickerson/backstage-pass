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

  private

  def generate_slug
    self.slug = name.parameterize
  end
  # 🚅 add methods above.
end
