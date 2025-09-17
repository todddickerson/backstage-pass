class Space < ApplicationRecord
  include DualIdSupport
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :team, counter_cache: true
  # 🚅 add belongs_to associations above.

  has_many :experiences, dependent: :destroy
  has_many :access_grants, as: :purchasable, dependent: :destroy
  has_many :all_streams, through: :experiences, source: :streams
  has_many :access_passes, dependent: :destroy
  # 🚅 add has_many associations above.

  has_rich_text :description
  # 🚅 add has_one associations above.

  scope :published, -> { where(published: true) }
  scope :with_experiences, -> { joins(:experiences).distinct }
  # 🚅 add scopes above.

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: {scope: :team_id}
  validates :team_id, uniqueness: true, unless: :allows_multiple_spaces?, if: :enforce_unique_space?
  # 🚅 add validations above.

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  after_update :clear_member_count_cache
  after_destroy :clear_member_count_cache
  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  extend FriendlyId
  friendly_id :slug, use: :slugged

  # Public URL for this space (root level)
  def public_url
    "/#{slug}"
  end

  # Full URL including domain
  def full_public_url
    "#{ENV.fetch("BASE_URL", "http://localhost:3020")}/#{slug}"
  end

  def live_experiences
    experiences.where(experience_type: :live_stream)
  end

  def active_streams
    all_streams.where(status: :live)
  end

  def total_viewers
    Rails.cache.fetch("space_#{id}/total_viewers", expires_in: 15.minutes) do
      User.joins(:access_grants)
        .where(access_grants: {purchasable: self, status: :active})
        .count
    end
  end

  def total_members
    Rails.cache.fetch("space_#{id}/total_members", expires_in: 15.minutes) do
      team.users.count + total_viewers_uncached
    end
  end

  # Uncached version for internal use
  def total_viewers_uncached
    User.joins(:access_grants)
      .where(access_grants: {purchasable: self, status: :active})
      .count
  end

  def can_access?(user)
    return false unless user

    # Team members always have full access
    return true if team.users.include?(user)

    # Space-level access grant gives access to the space (but not necessarily all experiences)
    user.access_grants.active.where(purchasable: self).exists?
  end

  def role_for_user(user)
    return nil unless user

    Rails.cache.fetch("space_#{id}/user_#{user.id}/role", expires_in: 30.minutes) do
      # Check team membership first (admin/editor roles)
      membership = team.memberships.find_by(user: user)
      return membership.role if membership

      # Check access grant (viewer role) - but this doesn't grant content access automatically
      access_grant = user.access_grants.active.where(purchasable: self).first
      return "viewer" if access_grant

      nil
    end
  end

  def user_can_manage?(user)
    return false unless user
    membership = team.memberships.find_by(user: user)
    return false unless membership
    %w[admin editor].include?(membership.role)
  end

  def user_can_view_space?(user)
    return false unless user
    can_access?(user) # Can access the space itself
  end

  def user_can_view_experience?(user, experience)
    return false unless user
    return false unless experience.space == self

    # Admin/Editor team members can view all experiences (core team)
    return true if user_can_manage?(user)

    # Viewers (including access grant holders) need specific content access
    # Check for specific experience access grant
    has_experience_grant = user.access_grants.active.where(purchasable: experience).exists?
    return true if has_experience_grant

    # Check for space-level access grant (grants access to all experiences in space)
    has_space_grant = user.access_grants.active.where(purchasable: self).exists?
    return true if has_space_grant

    false
  end

  def experiences_accessible_by(user)
    # Admin/Editor team members see everything
    return experiences if user_can_manage?(user)

    # For viewers (including access grant holders), check specific access
    accessible_experience_ids = user.access_grants.active
      .where(purchasable_type: "Experience")
      .where(purchasable_id: experience_ids)
      .pluck(:purchasable_id)

    # If user has space-level access grant, they can see all experiences
    if user.access_grants.active.where(purchasable: self).exists?
      return experiences
    end

    # Otherwise, only experiences they specifically purchased
    experiences.where(id: accessible_experience_ids)
  end

  def user_can_see_space_ui?(user)
    # Can they see the space interface (different from content access)
    return false unless user
    team.users.include?(user) # Must be a team member (any role)
  end

  def primary_space?
    team.spaces.first == self
  end

  # Cache management methods
  def clear_member_count_cache
    Rails.cache.delete("space_#{id}/total_viewers")
    Rails.cache.delete("space_#{id}/total_members")
  end

  def clear_user_role_cache(user_id)
    Rails.cache.delete("space_#{id}/user_#{user_id}/role")
  end

  def clear_all_user_caches
    # Clear all user-specific caches for this space
    # Note: This is expensive, use sparingly
    Rails.cache.delete_matched("space_#{id}/user_*/role")
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end

  def allows_multiple_spaces?
    # Future enhancement: allow multiple spaces per team
    false
  end

  def enforce_unique_space?
    # Only enforce uniqueness in production/development, not tests
    !Rails.env.test?
  end
  # 🚅 add methods above.
end
