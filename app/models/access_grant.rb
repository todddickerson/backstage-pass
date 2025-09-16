class AccessGrant < ApplicationRecord
  include DualIdSupport
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :team
  belongs_to :user
  belongs_to :purchasable, polymorphic: true
  belongs_to :access_pass, optional: true  # Which product was purchased
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  # 🚅 add has_one associations above.

<<<<<<< HEAD
  scope :active, -> { where(status: :active).where('expires_at > ? OR expires_at IS NULL', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :for_spaces, -> { where(purchasable_type: 'Space') }
  scope :for_experiences, -> { where(purchasable_type: 'Experience') }
=======
  scope :active, -> { where(status: :active).where("expires_at > ? OR expires_at IS NULL", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :for_spaces, -> { where(purchasable_type: "Space") }
  scope :for_experiences, -> { where(purchasable_type: "Experience") }
>>>>>>> main
  # 🚅 add scopes above.

  validates :status, presence: true
  validates :user_id, presence: true
  validates :purchasable_id, presence: true
  validates :purchasable_type, presence: true
  # 🚅 add validations above.

  before_validation :set_default_status
  after_create :create_team_membership
  after_update :sync_membership_status
  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  enum :status, {
<<<<<<< HEAD
    active: 'active',
    expired: 'expired',
    cancelled: 'cancelled',
    refunded: 'refunded'
  }

  def active?
    status&.to_s == 'active' && (expires_at.nil? || expires_at > Time.current)
=======
    active: "active",
    expired: "expired",
    cancelled: "cancelled",
    refunded: "refunded"
  }

  def active?
    status&.to_s == "active" && (expires_at.nil? || expires_at > Time.current)
>>>>>>> main
  end

  def space
    purchasable.is_a?(Space) ? purchasable : purchasable.space
  end

  def grants_access_to?(resource)
    return true if purchasable == resource
    return true if purchasable.is_a?(Space) && resource.respond_to?(:space) && resource.space == purchasable
    false
  end

  def description
    case purchasable_type
<<<<<<< HEAD
    when 'Space'
      "Full access to #{purchasable.name}"
    when 'Experience'
=======
    when "Space"
      "Full access to #{purchasable.name}"
    when "Experience"
>>>>>>> main
      "Access to #{purchasable.name} experience"
    else
      "Access grant"
    end
  end

  def target_team
    case purchasable_type
<<<<<<< HEAD
    when 'Space'
      purchasable.team
    when 'Experience'
=======
    when "Space"
      purchasable.team
    when "Experience"
>>>>>>> main
      purchasable.space.team
    else
      team
    end
  end

  def membership_for_user
    target_team.memberships.find_by(user: user)
  end

  private

  def set_default_status
<<<<<<< HEAD
    self.status = 'active' if status.blank?
=======
    self.status = "active" if status.blank?
>>>>>>> main
  end

  def create_team_membership
    return unless active?
    return if membership_for_user # Don't create duplicate memberships

<<<<<<< HEAD
    # Create membership with buyer role
    target_team.memberships.create!(
      user: user,
      role_ids: ['buyer'],
      source: 'access_pass'
=======
    viewer_role = Role.find_by(key: "viewer")
    target_team.memberships.create!(
      user: user,
      role_ids: [viewer_role.id],
      source: "access_pass"
>>>>>>> main
    )
  end

  def sync_membership_status
    membership = membership_for_user
    return unless membership
<<<<<<< HEAD
    return unless membership.source == 'access_pass'
=======
    return unless membership.source == "access_pass"
>>>>>>> main

    if active?
      # Reactivate membership if it was disabled
      # Note: Don't downgrade existing admin/editor roles
<<<<<<< HEAD
      if membership.role_ids.blank? || membership.role_ids.empty?
        membership.update!(role_ids: ['buyer'])
      end
=======
      membership.update!(role: "viewer") if membership.role.blank?
>>>>>>> main
    else
      # For granted access, we might want to keep them but mark differently
      # or remove them entirely depending on business logic
      # For now, let's keep the membership but could add a status field later
    end
  end
  # 🚅 add methods above.
end
