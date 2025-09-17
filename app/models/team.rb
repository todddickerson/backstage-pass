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
    spaces.first || (name.present? ? create_default_space : nil)
  end

  private

  def create_default_space
    return if spaces.exists? # Don't create if space already exists
    return unless name.present? # Don't create if team name is not set

    # Ensure name is a valid string before proceeding
    team_name = name.to_s.strip
    return if team_name.blank?

    space_name = "#{team_name}'s Space"
    space_slug = team_name.parameterize

    spaces.create!(
      name: space_name,
      slug: space_slug,
      description: "Welcome to #{team_name}'s exclusive content space!",
      published: false
    )
  end

  # 🚅 add methods above.
end
