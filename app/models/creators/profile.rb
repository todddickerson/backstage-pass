class Creators::Profile < ApplicationRecord
  # 🚅 add concerns above.
  
  belongs_to :user
  # 🚅 add belongs_to associations above.
  
  # 🚅 add has_many associations above.
  
  has_rich_text :bio
  # 🚅 add has_one associations above.
  
  # 🚅 add scopes above.
  
  validates :username, presence: true, uniqueness: true, 
                      format: { with: /\A[a-zA-Z0-9_-]+\z/, message: "can only contain letters, numbers, underscore and dash" },
                      length: { minimum: 2, maximum: 30 }
  validates :display_name, presence: true, length: { maximum: 100 }
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  # 🚅 add validations above.
  
  before_validation :normalize_username
  before_validation :set_display_name_from_username, if: -> { display_name.blank? }
  # 🚅 add callbacks above.
  
  delegate :email, :name, to: :user, prefix: false
  # 🚅 add delegations above.
  
  # FriendlyId for @username routes
  extend FriendlyId
  friendly_id :username, use: :slugged
  
  def to_param
    username
  end
  
  def profile_url
    "/#{username}"
  end
  
  # Get the user's primary space (for simplified UX)
  def primary_space
    user.teams.joins(:spaces).first&.spaces&.first
  end
  
  # Check if user has completed creator setup
  def setup_complete?
    username.present? && display_name.present? && primary_space.present?
  end
  
  # Get spaces the user can manage
  def manageable_spaces
    Space.joins(team: :memberships)
         .where(memberships: { user: user })
         .where(memberships: { role: %w[admin editor] })
  end
  
  private
  
  def normalize_username
    self.username = username&.downcase&.strip
  end
  
  def set_display_name_from_username
    self.display_name = username&.humanize
  end
  
  # 🚅 add methods above.
end
