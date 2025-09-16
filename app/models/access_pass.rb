class AccessPass < ApplicationRecord
  include DualIdSupport
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :space
  # 🚅 add belongs_to associations above.

  has_many :access_grants  # Track who purchased this product
  has_many :buyers, through: :access_grants, source: :user  # Users who bought this
  has_many :access_pass_experiences, dependent: :destroy
  has_many :experiences, through: :access_pass_experiences  # What's included in this pass
  # 🚅 add has_many associations above.

  has_rich_text :description
  # 🚅 add has_one associations above.

  scope :published, -> { where(published: true) }
  scope :available, -> { published.where('stock_limit IS NULL OR stock_limit > 0') }
  # 🚅 add scopes above.

  validates :name, presence: true
  validates :pricing_type, presence: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :slug, presence: true, uniqueness: { scope: :space_id }
  # 🚅 add validations above.

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # Pricing types enum
  enum :pricing_type, {
    free: 'free',
    one_time: 'one_time',
    monthly: 'monthly',
    yearly: 'yearly'
  }

  # FriendlyId for URL slugs
  extend FriendlyId
  friendly_id :slug, use: :slugged

  # Monetize price
  # monetize :price_cents

  def price_display
    return 'Free' if pricing_type == 'free' || price_cents.zero?
    
    price_str = "$#{(price_cents / 100.0).round(2)}"
    
    case pricing_type
    when 'monthly'
      "#{price_str}/month"
    when 'yearly'
      "#{price_str}/year"
    else
      price_str
    end
  end

  def recurring?
    %w[monthly yearly].include?(pricing_type)
  end

  def free?
    pricing_type == 'free' || price_cents.zero?
  end

  def available?
    published? && (stock_limit.nil? || stock_limit > 0)
  end

  def unlimited_stock?
    stock_limit.nil?
  end

  def stock_remaining
    return nil if unlimited_stock?
    stock_limit
  end

  def public_url
    "/#{space.slug}/#{slug}"
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
  # 🚅 add methods above.
end
