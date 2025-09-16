class Ability
  include CanCan::Ability
  include Roles::Permit

  if billing_enabled?
    include Billing::AbilitySupport
  end

  def initialize(user)
    if user.present?

      # permit is a Bullet Train created "magic" method. It parses all the roles in `config/roles.yml` and automatically inserts the appropriate `can` method calls here
      permit user, through: :memberships, parent: :team

      # INDIVIDUAL USER PERMISSIONS.
      can :manage, User, id: user.id
      can :read, User, id: user.collaborating_user_ids
      can :destroy, Membership, user_id: user.id
      can :manage, Invitation, id: user.teams.map(&:invitations).flatten.map(&:id)

      can :create, Team

      # We only allow users to work with the access tokens they've created, e.g. those not created via OAuth2.
      can :manage, Platform::AccessToken, application: {team_id: user.team_ids}, provisioned: true

      if stripe_enabled?
        can [:read, :create, :destroy], Oauth::StripeAccount, user_id: user.id
        can :manage, Integrations::StripeInstallation, team_id: user.team_ids
        can :destroy, Integrations::StripeInstallation, oauth_stripe_account: {user_id: user.id}
      end

      # 🚅 super scaffolding will insert any new oauth providers above.

      if billing_enabled?
        apply_billing_abilities user
      end
      
      # Buyer-specific permissions
      # Buyers get access based on their AccessGrants, not just team membership
      user.access_grants.active.includes(:access_pass).each do |grant|
        # Can view the space they purchased from
        can :read, Space, id: grant.access_pass.space_id
        
        # Can view the access pass they purchased
        can :read, AccessPass, id: grant.access_pass_id
        
        # Can view experiences included in their access pass
        if grant.access_pass.access_pass_experiences.any?
          experience_ids = grant.access_pass.access_pass_experiences.pluck(:experience_id)
          can :read, Experience, id: experience_ids
        end
        
        # Can view their own access grants
        can :read, AccessGrant, user_id: user.id
        
        # Can view their own purchases
        can :read, Billing::Purchase, user_id: user.id
      end

      if user.developer?
        # the following admin abilities were added by super scaffolding.
      end
    end
  end
end
