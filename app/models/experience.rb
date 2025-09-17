class Experience < ApplicationRecord
  include DualIdSupport
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :space
  # 🚅 add belongs_to associations above.

  has_many :access_grants, as: :purchasable, dependent: :destroy
  has_many :streams, dependent: :destroy
  has_many :access_pass_experiences, dependent: :destroy
  has_many :access_passes, through: :access_pass_experiences
  # 🚅 add has_many associations above.

  has_one :team, through: :space
  has_rich_text :description
  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  enum :experience_type, {
    live_stream: "live_stream",
    course: "course",
    community: "community",
    consultation: "consultation",
    digital_product: "digital_product"
  }

  validates :name, presence: true
  validates :experience_type, presence: true
  validates :price_cents, presence: true, numericality: {greater_than_or_equal_to: 0}
  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # monetize :price_cents

  def live_streaming?
    experience_type == "live_stream"
  end

  def requires_real_time?
    %w[live_stream consultation].include?(experience_type)
  end

  def price_display
    price_cents.zero? ? "Free" : "$#{(price_cents / 100.0).round(2)}"
  end

  def user_can_manage?(user)
    space.user_can_manage?(user)
  end

  def user_can_view?(user)
    space.user_can_view_experience?(user, self)
  end

  def user_can_join_stream?(user)
    return false unless user_can_view?(user)
    return false unless live_streaming?
    true
  end

  def accessible_by?(user)
    user_can_view?(user)
  end

  # Bullet Train pattern for select options
  def self.experience_type_options
    experience_types.keys.map do |type|
      [human_attribute_name("experience_type.#{type}"), type]
    end
  end
  # 🚅 add methods above.
end
