# Bullet Train Authorization Patterns - Critical Documentation

## Overview
This document captures critical learnings about Bullet Train's authorization system from deep research conducted on Sept 17, 2025. This information is essential for properly implementing controllers and authorization in the Backstage Pass application.

## Key Concepts

### 1. Team-Centric Architecture
- **Resources belong to Teams, NOT Users**
- Users access resources through Memberships in Teams
- Memberships have Roles that determine permissions

### 2. Authorization Patterns

#### Standard Pattern (for Team-scoped resources)
```ruby
class Account::SpacesController < Account::ApplicationController
  account_load_and_authorize_resource :space, through: :team, through_association: :spaces
end
```

#### Teams Controller Exception
```ruby
class Account::TeamsController < Account::ApplicationController
  # DO NOT use account_load_and_authorize_resource
  # Teams are accessed directly through user.teams
  
  def index
    @teams = current_user.teams
    redirect_to account_team_path(@teams.first) if @teams.count == 1
  end
  
  def show
    @team = current_user.teams.find(params[:id])
  end
end
```

### 3. Critical Patterns to Remember

#### account_load_and_authorize_resource
- **Purpose**: Team-aware version of CanCanCan's load_and_authorize_resource
- **Usage**: For resources that belong to teams
- **Syntax**: 
  ```ruby
  account_load_and_authorize_resource :resource_name, through: :parent, through_association: :association
  ```
- **DO NOT USE prepend_before_action** - This causes execution order issues

#### Manual Resource Loading Pattern
When you need explicit control:
```ruby
before_action :set_team
before_action :set_resource, only: [:show, :edit, :update, :destroy]
before_action :build_resource, only: [:new, :create]

private

def set_team
  @team = current_user.teams.find(params[:team_id])
end

def set_resource
  @resource = @team.resources.find(params[:id])
end

def build_resource
  @resource = @team.resources.build
end
```

### 4. Ability Class Configuration

The Ability class uses the `permit` helper to translate YAML role configurations:

```ruby
class Ability
  include CanCan::Ability
  
  def initialize(user)
    if user.present?
      # Bullet Train magic method that parses config/roles.yml
      permit user, through: :memberships, parent: :team
      
      # Individual user permissions
      can :manage, User, id: user.id
      can :create, Team  # Users can create teams
      
      # Team members get access through memberships
      can :read, Team, id: user.team_ids
      can :manage, Team, id: user.administrated_team_ids
    end
  end
end
```

### 5. Common Issues and Solutions

#### Issue: 403 Forbidden on Teams Controller
**Cause**: Using account_load_and_authorize_resource on TeamsController
**Solution**: Teams are special - access them directly through current_user.teams

#### Issue: Execution order problems
**Cause**: Using prepend_before_action with authorization
**Solution**: Use standard before_action filters

#### Issue: Resources not scoped to team
**Cause**: Not using team-aware loading patterns
**Solution**: Use account_load_and_authorize_resource with proper through associations

### 6. Testing Authorization

```ruby
class Account::SomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @user = create(:onboarded_user)
    sign_in @user
    @team = @user.current_team
    @resource = create(:resource, team: @team)
  end
  
  test "should get index" do
    get account_team_resources_url(@team)
    assert_response :success
  end
end
```

### 7. View Helpers

```erb
<% if can? :edit, @resource %>
  <%= link_to "Edit", edit_path(@resource) %>
<% end %>
```

### 8. YAML Role Configuration (config/models/roles.yml)

```yaml
default:
  models:
    Space: read
    Experience: read
    Stream: read

admin:
  includes:
    - default
  models:
    Team: manage
    Space: manage
    Experience: manage
    Stream: manage
    AccessPass: manage
    AccessGrant: manage
```

## Critical Learnings

1. **Teams are the authorization boundary** - Everything flows through team membership
2. **Don't fight the framework** - Use the patterns Bullet Train provides
3. **account_load_and_authorize_resource is your friend** - But NOT for Teams controller
4. **Memberships + Roles = Permissions** - This is the core equation
5. **Resources belong to Teams** - Not to Users directly

## Implementation Checklist

When creating a new controller:
- [ ] Determine if resource belongs to a team
- [ ] If yes, use `account_load_and_authorize_resource`
- [ ] If it's Teams controller, use manual loading through `current_user.teams`
- [ ] Create proper views (new, edit, show, index)
- [ ] Add strong parameters method
- [ ] Write tests with proper team setup
- [ ] Verify authorization works for different roles

## References
- Bullet Train Roles Documentation
- CanCanCan Integration Patterns
- Team-based Multi-tenancy Architecture

## Last Updated
Sept 17, 2025 - After comprehensive Perplexity research on Bullet Train authorization patterns