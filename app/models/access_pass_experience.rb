class AccessPassExperience < ApplicationRecord
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :access_pass
  belongs_to :experience
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  has_one :team, through: :access_pass
  has_one :space, through: :access_pass
  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  validates :experience_id, presence: true
  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # 🚅 add methods above.
end
