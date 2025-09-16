class Billing::Purchase < ApplicationRecord
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :team
  belongs_to :user
  belongs_to :access_pass, optional: true
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  validates :user, scope: true
  validates :access_pass, scope: true
  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  def valid_users
    # Any user can make a purchase
    User.all
  end

  def valid_access_passes
    # Access passes from any space in this team
    AccessPass.joins(:space).where(spaces: { team_id: team_id })
  end

  # 🚅 add methods above.
end
