class User < ApplicationRecord
  include Users::Base
  include Roles::User
  # 🚅 add concerns above.

  # 🚅 add belongs_to associations above.

  has_many :access_grants, dependent: :destroy
  
  # Through associations to simplify controller queries
  has_many :spaces, through: :teams
  has_many :experiences, through: :spaces
  has_many :streams, through: :experiences
  # 🚅 add has_many associations above.

  # 🚅 add oauth providers above.

  has_one :creator_profile, class_name: "Creators::Profile", dependent: :destroy
  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # 🚅 add methods above.
end
