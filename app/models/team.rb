class Team < ApplicationRecord
  include Teams::Base
  include Webhooks::Outgoing::TeamSupport
  # 🚅 add concerns above.

  # 🚅 add belongs_to associations above.

  has_many :spaces, dependent: :destroy
  has_many :access_grants, dependent: :destroy
  has_many :billing_purchases, class_name: "Billing::Purchase", dependent: :destroy
  # 🚅 add has_many associations above.

  # 🚅 add oauth providers above.

  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  # 🚅 add validations above.

  after_create :create_default_space
  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # Get the primary space (UI shows this as "Your Space" instead of "Your Spaces")
  def primary_space
    spaces.first || create_default_space
  end
  
  private
  
  def create_default_space
    return if spaces.exists? # Don't create if space already exists
    
    spaces.create!(
      name: "#{name}'s Space",
      slug: name.parameterize,
      description: "Welcome to #{name}'s exclusive content space!",
      published: false # Creator can publish when ready
    )
  end
  
  # 🚅 add methods above.
end
