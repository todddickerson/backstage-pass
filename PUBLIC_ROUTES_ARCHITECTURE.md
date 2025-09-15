# Public Routes Architecture

## 🔴 CRITICAL: Public Routes Do NOT Need Team Context

This is a fundamental architectural principle that must be understood:

**Public routes bypass Bullet Train's team-scoped patterns entirely. They are for unauthenticated users and public viewing.**

## Route Categories

### 1. Public Routes (NO Team Context)
These routes are completely outside Bullet Train's team authorization system:

```ruby
# ✅ CORRECT: Public routes bypass team context
scope module: 'public' do
  # Creator profiles
  get '@:username', to: 'creator_profiles#show'
  
  # Space discovery
  get ':space_slug', to: 'spaces#show'
  resources :spaces, only: [:index], path: 'discover'
  
  # Access pass sales pages
  get ':space_slug/:pass_slug', to: 'access_passes#show'
  
  # Purchase flow (before auth)
  resources :purchases, only: [:new, :create]
  
  # Passwordless auth
  namespace :auth do
    resources :sessions, only: [:new, :create]
  end
end
```

### 2. Account Routes (Team Context Required)
These routes follow Bullet Train's team-scoped patterns:

```ruby
# Team management - REQUIRES team context
namespace :account do
  # Creator managing their space
  resource :space do  # Singular because one per team
    resources :experiences
    resources :access_passes
    resources :streams
  end
  
  # Team settings
  resources :teams do
    resources :memberships
    resources :invitations
  end
end
```

### 3. Member Routes (Purchased Content Access)
These routes check AccessPass ownership, not team membership:

```ruby
# Member area - checks AccessPass, not team membership
namespace :account do  # Still in account namespace for auth
  resources :purchased_spaces, only: [:index, :show] do
    resources :experiences, only: [:show] do
      member do
        get :stream  # Watch live stream
        get :chat    # Join chat
      end
    end
  end
end
```

## Controller Implementation

### Public Controllers (No Team Context)

```ruby
# app/controllers/public/application_controller.rb
class Public::ApplicationController < ApplicationController
  # NO team context
  # NO authentication required
  # NO Bullet Train authorization
  
  # Just basic Rails controller
end

# app/controllers/public/spaces_controller.rb
class Public::SpacesController < Public::ApplicationController
  def show
    # Find by slug, not through team
    @space = Space.published.friendly.find(params[:space_slug])
    
    # No authorization check - it's public!
    # No team context needed
    
    # But we can still get team info if needed
    @team = @space.team  # For billing/analytics
  end
end

# app/controllers/public/creator_profiles_controller.rb
class Public::CreatorProfilesController < Public::ApplicationController
  def show
    # Direct lookup - no team scope
    @profile = Creators::Profile.find_by!(username: params[:username])
    @spaces = @profile.user.teams.flat_map(&:spaces).select(&:published?)
  end
end
```

### Account Controllers (With Team Context)

```ruby
# app/controllers/account/spaces_controller.rb
class Account::SpacesController < Account::ApplicationController
  # This DOES use team context - for creators managing their space
  account_load_and_authorize_resource :space, through: :team, through_association: :spaces
  
  def show
    # @space is already loaded and authorized through team
  end
end
```

### Member Controllers (AccessPass Authorization)

```ruby
# app/controllers/account/purchased_spaces_controller.rb
class Account::PurchasedSpacesController < Account::ApplicationController
  # Requires authentication but NOT team membership
  
  def index
    # Show spaces the user has purchased access to
    @spaces = current_user.purchased_spaces
  end
  
  def show
    @space = Space.find(params[:id])
    
    # Check AccessPass, not team membership
    unless current_user.has_access_to?(@space)
      redirect_to public_space_path(@space), alert: "Purchase required"
    end
  end
end
```

## Database Queries

### Public Queries (No Team Scope)

```ruby
# ✅ CORRECT for public routes
Space.published.friendly.find(params[:slug])
Creators::Profile.find_by(username: params[:username])
AccessPass.available.where(space: @space)

# ❌ WRONG for public routes
current_team.spaces  # No current_team in public context!
@team.spaces.find(params[:id])  # Don't scope through team
```

### Account Queries (Team Scoped)

```ruby
# ✅ CORRECT for account routes
current_team.spaces
current_team.spaces.find(params[:id])
@space = current_team.primary_space
```

## URL Structure

### Public URLs (Clean, No Team Reference)
```
backstagepass.app/@jakemiller         # Creator profile
backstagepass.app/jakes-music-space   # Space page
backstagepass.app/jakes-music-space/vip-pass  # Access pass
backstagepass.app/discover            # Browse all spaces
backstagepass.app/live                # Currently streaming
```

### Account URLs (Team Context)
```
backstagepass.app/account/teams/1/edit     # Team settings
backstagepass.app/account/space            # Manage your space
backstagepass.app/account/space/experiences # Manage experiences
backstagepass.app/account/space/analytics   # View analytics
```

### Member URLs (Purchased Access)
```
backstagepass.app/account/purchased_spaces           # My purchases
backstagepass.app/account/purchased_spaces/1         # Space I bought
backstagepass.app/account/purchased_spaces/1/stream  # Watch stream
```

## Why This Matters

1. **User Experience**: Clean public URLs without `/teams/123/` noise
2. **SEO**: Search engines can index public pages
3. **Conversion**: Reduce friction in purchase flow
4. **Separation of Concerns**: Public viewing vs team management
5. **Framework Compliance**: Work WITH Rails patterns, not against them

## Common Mistakes to Avoid

```ruby
# ❌ WRONG: Don't use team context in public controllers
class Public::SpacesController < Account::ApplicationController  # WRONG!
  account_load_and_authorize_resource :space  # NO!
end

# ❌ WRONG: Don't require authentication for public pages
class Public::SpacesController < Public::ApplicationController
  before_action :authenticate_user!  # NO!
end

# ❌ WRONG: Don't scope through team in public routes
def show
  @space = current_team.spaces.find(params[:id])  # NO current_team!
end

# ✅ CORRECT: Direct lookup for public content
def show
  @space = Space.published.friendly.find(params[:space_slug])  # YES!
end
```

## Testing Public Routes

```ruby
# test/controllers/public/spaces_controller_test.rb
class Public::SpacesControllerTest < ActionDispatch::IntegrationTest
  test "can view published space without authentication" do
    space = create(:space, :published, slug: "test-space")
    
    # No sign_in needed!
    get "/test-space"
    
    assert_response :success
    assert_select "h1", space.name
  end
  
  test "cannot view unpublished space" do
    space = create(:space, :unpublished)
    
    get "/#{space.slug}"
    
    assert_response :not_found
  end
end
```

## Key Takeaway

**Public routes are PUBLIC. They don't need team context, authentication, or authorization. They're for discovery, marketing, and purchases. Keep them simple and accessible.**

This is standard Rails practice and completely compatible with Bullet Train - the framework expects you to have public routes outside the team context.