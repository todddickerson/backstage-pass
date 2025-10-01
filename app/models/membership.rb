class Membership < ApplicationRecord
  include Memberships::Base
  # 🚅 add concerns above.

  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  # 🚅 add oauth providers above.

  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # Check if this membership is a buyer role
  def buyer?
    role_ids.include?("buyer")
  end

  # Check if this membership is an editor role
  def editor?
    role_ids.include?("editor")
  end

  # Check if this membership can manage team settings
  def can_manage_team?
    admin? || editor?
  end

  # 🚅 add methods above.
end
