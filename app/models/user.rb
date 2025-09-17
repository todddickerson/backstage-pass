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

  # Override Bullet Train's create_default_team to ensure team has a name
  def create_default_team
    # Temporarily disable the after_create callback for space creation
    Team.skip_callback(:create, :after, :create_default_space)

    begin
      # Call the original method from Bullet Train
      super

      # Ensure the team has a proper name
      if current_team && current_team.name.blank?
        team_name = "#{first_name} #{last_name}'s Team"
        current_team.update_column(:name, team_name)
        current_team.reload
      end

      # Now manually create the default space with proper name
      current_team&.send(:create_default_space)
    ensure
      # Re-enable the callback for future team creations
      Team.set_callback(:create, :after, :create_default_space)
    end
  end

  # 🚅 add methods above.
end
