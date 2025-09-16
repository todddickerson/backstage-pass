# Buyer Account Architecture

## Research Findings: How Whop Handles Buyers

After researching Whop's approach, we found that they keep buyers **completely separate** from seller organizations:
- Buyers have their own independent accounts
- Buyers access purchased content through their "Whop Hub" 
- Buyers are NOT added as members to seller teams/organizations
- Permissions are granted through product purchases, not team membership

## Backstage Pass Approach: Buyer Membership Model

Based on user feedback and Bullet Train's architecture, we'll add buyers as special members to creator teams:

### Core Decision: Buyers as Team Members
When a buyer purchases an AccessPass:
- They get added as a "buyer" member to the creator's team
- This gives them navigation/UI access within Bullet Train's framework
- Actual permissions are controlled by AccessGrant records
- Works seamlessly with Bullet Train's existing authorization system

### Why This Approach Works Best
1. **Bullet Train Native**: Uses existing Team/Membership patterns
2. **Clean Authorization**: CanCan already understands team membership
3. **Natural Navigation**: Buyers can see teams they've purchased from
4. **No Extra Infrastructure**: No need for separate buyer dashboards
5. **Future Proof**: Can easily add buyer-specific features later

### AccessGrant Remains the Source of Truth
The AccessGrant model determines actual access:
- Even with team membership, access is controlled by AccessGrant
- AccessGrant tracks what was purchased, expiration, status
- Team membership enables UI access, AccessGrant enables content access

## Implementation Plan

### Step 1: Add Buyer Role to Membership Model
```ruby
class Membership < ApplicationRecord
  # Add buyer role to existing roles
  ROLES = [:admin, :editor, :viewer, :buyer].freeze
  
  def buyer?
    role_ids.include?('buyer')
  end
  
  def can_manage_team?
    admin? || editor?
  end
end
```

### Step 2: Add Buyer to Team on Purchase
```ruby
class PurchaseService
  def complete_purchase(user, access_pass)
    # Create the AccessGrant
    access_grant = AccessGrant.create!(
      user: user,
      team: access_pass.space.team,
      purchasable: access_pass.purchasable,
      access_pass: access_pass,
      status: 'active'
    )
    
    # Add buyer as viewer member to the team
    team = access_pass.space.team
    unless user.teams.include?(team)
      Membership.create!(
        user: user,
        team: team,
        role_ids: ['buyer']
      )
    end
    
    access_grant
  end
end
```

### Step 3: Update Authorization
```ruby
class Ability
  include CanCan::Ability
  
  def initialize(user)
    if user.present?
      user.memberships.each do |membership|
        team = membership.team
        
        if membership.admin? || membership.editor?
          # Full team management
          can :manage, Space, team: team
          can :manage, AccessPass, space: { team: team }
        elsif membership.viewer? || membership.buyer?
          # Read-only access
          can :read, Space, team: team
          
          # Access based on purchases
          user.access_grants.active.each do |grant|
            can :view, Experience, id: grant.access_pass.experience_ids
            can :join, Stream, experience: { id: grant.access_pass.experience_ids }
          end
        end
      end
    end
  end
end
```

## Benefits of This Approach

1. **Bullet Train Compliance**: Works within existing Team/Membership structure
2. **Clean Navigation**: Buyers can see teams they've purchased from
3. **Clear Permissions**: AccessGrant controls actual access
4. **Scalable**: Can handle buyers with multiple purchases from different creators
5. **Natural Progression**: Buyers can later create their own team to become sellers

## Future Seller Onboarding

When a buyer wants to become a creator:
1. They'll be prompted to create their first team
2. Team creation wizard guides them through setup
3. Their existing purchases remain intact
4. They now have both buyer and seller capabilities
5. Single account can be both consumer and creator

## UI Considerations

### For Buyers:
- See purchased content in team context
- Cannot access team management features
- "Become a Creator" prompt when ready

### For Creators:
- Can see buyers in team member list (marked as buyers)
- Cannot assign admin/editor roles to buyers
- Analytics show buyer engagement

## Why Not Separate Buyer Accounts?

We considered Whop's approach (completely separate buyers) but chose team membership because:
- **Bullet Train Native**: Uses existing patterns without major changes
- **Simpler Implementation**: No need for separate routing/auth systems
- **Natural UX**: Buyers navigate within familiar team structure
- **Easy Upgrade Path**: Buyers can seamlessly become creators

## Next Steps

1. ✅ Research completed
2. ✅ Decision made: Buyers as team members
3. ⏳ Update Membership model with buyer role
4. ⏳ Create PurchaseService
5. ⏳ Update authorization rules
6. ⏳ Test purchase flow end-to-end

## Summary

**Final Decision**: Buyers are added as special "buyer" members to creator teams when they purchase AccessPasses. This approach:
- Works perfectly with Bullet Train's architecture
- Requires minimal changes to existing code
- Provides clean authorization through CanCan
- Allows buyers to later become creators naturally
- Keeps the codebase simple and maintainable