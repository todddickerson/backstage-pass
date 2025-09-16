# Backstage Pass Routing Architecture

## Overview
Backstage Pass uses a carefully designed routing structure that prioritizes clean, marketing-friendly URLs for public-facing pages while maintaining Bullet Train's conventions for authenticated account areas.

## URL Structure

### Public Routes (No Authentication Required)

#### 1. **Creator Profiles**
```
https://backstagepass.com/@username
```
- Creator profile pages with `@` prefix for clear differentiation
- Example: `backstagepass.com/@johndoe`
- Handled by: `Public::CreatorProfilesController#show`

#### 2. **Space Landing Pages** 
```
https://backstagepass.com/space-slug
```
- Root-level URLs for maximum brand visibility
- Clean URLs for marketing campaigns and social sharing
- Example: `backstagepass.com/tech-talks-pro`
- Handled by: `Public::SpacesController#show`

#### 3. **Access Pass Sales Pages**
```
https://backstagepass.com/space-slug/access-pass-slug
```
- Nested under spaces for logical hierarchy
- Example: `backstagepass.com/tech-talks-pro/monthly-membership`
- Handled by: `Public::AccessPassesController#show`

#### 4. **Static Pages**
```
https://backstagepass.com/about
https://backstagepass.com/terms
https://backstagepass.com/privacy
```
- Standard static pages at root level
- Must be defined BEFORE catch-all routes

#### 5. **Marketplace Browse**
```
https://backstagepass.com/explore
```
- Browse all public spaces
- Handled by: `Public::SpacesController#index`

### Account Routes (Authentication Required)

All authenticated routes live under `/account` namespace per Bullet Train conventions:

```
/account                          # Dashboard
/account/teams/1/spaces           # Manage spaces
/account/teams/1/spaces/1/edit    # Edit space
/account/teams/1/access_passes    # Manage access passes
/account/creator_profile          # Edit creator profile
/account/settings                 # User settings
```

## Routing Priority (CRITICAL)

The order of route definitions in `config/routes.rb` is crucial:

```ruby
scope module: "public" do
  # 1. Root route
  root to: "home#index"
  
  # 2. Static pages (must come before catch-all)
  get "about", to: "pages#about"
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"
  
  # 3. Special routes (explore, etc.)
  get "explore", to: "spaces#index"
  
  # 4. Creator profiles with @ prefix
  get "/@:username", to: "creator_profiles#show"
  
  # 5. CATCH-ALL routes (MUST BE LAST!)
  # Access pass pages (more specific, so comes first)
  get "/:space_slug/:access_pass_slug", to: "access_passes#show"
  
  # Space pages (less specific, so comes last)
  get "/:space_slug", to: "spaces#show"
end
```

## Why This Architecture?

### Marketing Benefits
- **Premium URLs**: Spaces get root-level URLs for maximum impact
- **Brand-friendly**: No `/spaces/` prefix cluttering the URL
- **Social sharing**: Clean URLs look better in social media posts
- **SEO optimized**: Shorter URLs with keywords at root level

### Technical Benefits
- **Clear hierarchy**: Predictable URL structure
- **No conflicts**: @ prefix prevents username/space collisions
- **Extensible**: Easy to add new route types above catch-all
- **Bullet Train compatible**: Account area follows BT conventions

## Implementation Details

### Controllers

**Public::SpacesController**
```ruby
def show
  # Direct slug lookup for root-level routes
  @space = Space.friendly.find(params[:space_slug])
  
  # Must be published
  unless @space.published?
    raise ActiveRecord::RecordNotFound
  end
end
```

**Public::AccessPassesController**
```ruby
def show
  # Find space first
  @space = Space.friendly.find(params[:space_slug])
  
  # Then find access pass
  @access_pass = @space.access_passes.friendly.find(params[:access_pass_slug])
end
```

### Model Helpers

**Space model**
```ruby
# Public URL for this space (root level)
def public_url
  "/#{slug}"
end

# Full URL including domain
def full_public_url
  "#{ENV['BASE_URL']}/#{slug}"
end
```

**AccessPass model**
```ruby
# Public URL for this access pass
def public_url
  "/#{space.slug}/#{slug}"
end
```

## Adding New Routes

### CRITICAL: Maintain Route Order!

When adding new routes:

1. **Static/known routes** - Add above `/@:username`
2. **Dynamic but specific** - Add above catch-all routes
3. **New catch-all patterns** - Must go at the very bottom

Example:
```ruby
# ✅ CORRECT - Static route above catch-all
get "blog", to: "blog#index"       # Add here
get "/@:username", to: "..."       # Existing
get "/:space_slug", to: "..."      # Existing catch-all

# ❌ WRONG - Will break space routes!
get "/@:username", to: "..."       
get "/:space_slug", to: "..."
get "blog", to: "blog#index"       # Too late!
```

## Testing Routes

### Route Helpers
```ruby
# In views/controllers
public_space_path("tech-talks")              # => "/tech-talks"
public_space_url("tech-talks")               # => "https://backstagepass.com/tech-talks"
creator_profile_path("johndoe")              # => "/@johndoe"
public_space_access_pass_path("tech-talks", "monthly")  # => "/tech-talks/monthly"

# In models
space.public_url                             # => "/tech-talks"
space.full_public_url                        # => "https://backstagepass.com/tech-talks"
```

### Testing Priority
```bash
# Test route priority
rails routes | grep "GET    /"

# Should show in this order:
GET    /                          # Root
GET    /about                     # Static pages
GET    /terms
GET    /explore                   # Special routes
GET    /@:username               # Creator profiles
GET    /:space_slug/:access_pass # Access passes (more specific)
GET    /:space_slug              # Spaces (less specific)
```

## Common Pitfalls

### 1. Adding routes after catch-all
❌ **Wrong**: Adding new routes after `/:space_slug` - they'll never match!

### 2. Forgetting constraints
❌ **Wrong**: Not adding regex constraints can cause routing conflicts

### 3. Using prefixed routes
❌ **Wrong**: Using `/spaces/slug` instead of `/slug` defeats the purpose

### 4. Breaking Bullet Train conventions
❌ **Wrong**: Moving account routes out of `/account` namespace

## Future Considerations

### Reserved Slugs
Consider maintaining a list of reserved slugs that can't be used for spaces:
- about, terms, privacy, explore
- account, admin, api, webhooks
- login, signup, signin, signout
- help, support, contact

### Subdomain Support
Future enhancement could use subdomains:
- `space-name.backstagepass.com`
- `creator.backstagepass.com/@username`

### API Versioning
API routes follow Bullet Train conventions:
- `/api/v1/spaces`
- `/api/v1/access_passes`

## Troubleshooting

### Route Not Found
1. Check route order in `routes.rb`
2. Verify slug format matches constraints
3. Check if space/resource is published
4. Use `rails routes` to verify

### Wrong Controller Hit
1. Route order issue - more specific routes must come first
2. Missing constraints on catch-all routes
3. Conflicting route patterns

### Development vs Production
- Development: `http://localhost:3020/space-slug`
- Production: `https://backstagepass.com/space-slug`
- Use `ENV['BASE_URL']` for environment-specific URLs

---

**Remember**: Route order matters! Always add new routes ABOVE catch-all patterns.