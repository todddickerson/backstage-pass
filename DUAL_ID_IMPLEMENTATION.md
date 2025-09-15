# Dual ID Implementation: FriendlyId + Bullet Train ObfuscatesId

## Overview

This document explains our solution to the conflict between FriendlyId slugs and Bullet Train's obfuscated IDs, providing a comprehensive approach that supports both public-facing human-readable URLs and secure admin operations.

## Problem Analysis

### Root Cause
The conflict arose from both FriendlyId and Bullet Train's ObfuscatesId gem overriding the same `to_param` method:

1. **Bullet Train ObfuscatesId** overrides `to_param` to return `obfuscated_id` (e.g., "vjeWJZ")
2. **FriendlyId** overrides `to_param` to return the slug (e.g., "test-space")
3. **Conflict**: FriendlyId wins, causing URLs to use slugs
4. **Error**: Bullet Train's `find` method tries to decode "test-space" as HashIds → "unable to unhash" error

### Error Chain
```ruby
# URL generation uses FriendlyId slug
space_path(@space) # → "/account/spaces/test-space"

# Bullet Train tries to decode "test-space" as HashIds
Space.find("test-space") 
# → ObfuscatesId#decode_id("test-space")
# → HashIds#decode("test-space") 
# → "unable to unhash" error
```

## Solution Architecture

### Dual ID Strategy
Our solution provides the best of both worlds:

- **Public Routes**: Use FriendlyId slugs for SEO and UX (`/spaces/gaming-hub`)
- **Admin Routes**: Use obfuscated IDs for security (`/account/spaces/vjeWJZ`)
- **API Routes**: Support both formats for maximum flexibility

### Components

#### 1. DualIdSupport Concern (`app/models/concerns/dual_id_support.rb`)

**Purpose**: Enables models to handle both slug and obfuscated ID lookups safely.

**Key Methods**:
- `to_param` - Returns slug if available, otherwise obfuscated ID
- `admin_param` - Always returns obfuscated ID for admin use
- `find_by_any_id(id)` - Tries multiple lookup strategies
- `find(*ids)` - Enhanced finder with recursion protection

**Lookup Strategy**:
1. Try FriendlyId first (handles slugs and numeric IDs)
2. If that fails, try obfuscated ID decoding
3. Finally fallback to standard ActiveRecord find

```ruby
# Example usage
Space.find_by_any_id("gaming-hub")  # Finds by slug
Space.find_by_any_id("vjeWJZ")       # Finds by obfuscated ID  
Space.find_by_any_id("1")            # Finds by integer ID
```

#### 2. DualIdFinder Controller Concern (`app/controllers/concerns/dual_id_finder.rb`)

**Purpose**: Provides controller helpers for finding resources with appropriate context.

**Key Methods**:
- `find_resource(model, id, admin_context: false)` - Context-aware finder
- `looks_like_slug?(id)` - Heuristic detection for debugging
- `url_param_for(record, context: :public)` - Generate appropriate URL params

#### 3. Separate Controller Namespaces

**Public Controllers** (`app/controllers/public/`):
- No authentication required
- Use slug-based URLs for SEO
- Example: `/spaces/gaming-hub`

**Account Controllers** (`app/controllers/account/`):
- Authentication required
- Use obfuscated IDs for security  
- Example: `/account/spaces/vjeWJZ`

### Implementation Details

#### Model Setup
```ruby
class Space < ApplicationRecord
  include DualIdSupport  # Enable dual ID support
  
  extend FriendlyId
  friendly_id :slug, use: :slugged
  
  # Bullet Train's ObfuscatesId is automatically included via Records::Base
end
```

#### Controller Setup
```ruby
# Public controller
class Public::SpacesController < Public::ApplicationController
  include DualIdFinder
  
  def show
    @space = find_resource(Space, params[:space_slug], prefer_slug: true)
  end
end

# Admin controller  
class Account::SpacesController < Account::ApplicationController
  include DualIdFinder
  # Uses obfuscated IDs automatically via Bullet Train's scaffolding
end
```

#### Route Configuration
```ruby
# Public routes with slug parameters
scope module: "public" do
  resources :spaces, only: [:index, :show], param: :space_slug
end

# Admin routes with obfuscated ID parameters (Bullet Train default)
namespace :account do
  resources :spaces  # Uses obfuscated IDs automatically
end
```

## Security Considerations

### Obfuscated ID Benefits
- **Enumeration Protection**: Prevents systematic resource discovery
- **Information Hiding**: Conceals business metrics (user count, growth rates)
- **Attack Surface Reduction**: Makes targeted attacks more difficult

### Implementation Security
- **Salt Management**: Uses Bullet Train's built-in salt configuration
- **Input Validation**: Robust error handling prevents information leakage
- **Context Separation**: Public and admin contexts use appropriate ID formats

### Best Practices
1. **Never expose obfuscated IDs in public contexts** - Use slugs for public URLs
2. **Always validate decoded IDs** - Check that decoded values are valid
3. **Use admin_param for internal operations** - Ensures consistent obfuscated ID usage
4. **Log decode failures for monitoring** - Track potential attacks or misconfigurations

## Testing Strategy

### Model Tests
```ruby
# Test dual ID functionality
def test_dual_id_support
  space = create(:space, slug: "test-space")
  
  # Test slug lookup
  assert_equal space, Space.find_by_any_id("test-space")
  
  # Test obfuscated ID lookup
  assert_equal space, Space.find_by_any_id(space.obfuscated_id)
  
  # Test parameter generation
  assert_equal "test-space", space.to_param
  assert_match /\A[a-zA-Z]{6,}\z/, space.admin_param
end
```

### Controller Tests
```ruby
# Test public access with slugs
def test_public_space_access
  space = create(:space, :published, slug: "test-space")
  get "/spaces/test-space"
  assert_response :success
end

# Test admin access with obfuscated IDs
def test_admin_space_access
  space = create(:space)
  get "/account/spaces/#{space.obfuscated_id}"
  assert_response :success
end
```

### Integration Tests
```ruby
# Test that both URL formats work correctly
def test_dual_url_access
  space = create(:space, :published)
  
  # Public slug URL
  assert_routing "/spaces/#{space.slug}", {
    controller: "public/spaces", 
    action: "show", 
    space_slug: space.slug
  }
  
  # Admin obfuscated URL  
  assert_routing "/account/spaces/#{space.obfuscated_id}", {
    controller: "account/spaces",
    action: "show",
    id: space.obfuscated_id
  }
end
```

## Troubleshooting

### Common Issues

#### "Unable to unhash" Errors
**Cause**: Trying to decode a slug as an obfuscated ID
**Solution**: Use `find_by_any_id` instead of direct `find`

#### Stack Overflow in find Methods
**Cause**: Recursion in overridden `find` method
**Solution**: Use `super` for fallback calls, not recursive `find`

#### Configuration Mismatches
**Cause**: Different HashIds settings between environments
**Solution**: Ensure consistent salt/alphabet settings in all environments

### Debugging Tools

#### Check ID Types
```ruby
# Identify what type of ID you're working with
def debug_id_type(id)
  puts "ID: #{id}"
  puts "Looks like slug: #{looks_like_slug?(id)}"
  puts "Looks like obfuscated: #{looks_like_obfuscated_id?(id)}"
  puts "Is numeric: #{id.to_s =~ /\A\d+\z/}"
end
```

#### Test Lookup Methods
```ruby
# Test all lookup strategies
def test_all_lookups(model_class, id)
  puts "Testing lookups for #{model_class.name}##{id}"
  
  # Try each method individually
  begin
    result = model_class.friendly.find(id)
    puts "FriendlyId: #{result.id}"
  rescue => e
    puts "FriendlyId failed: #{e.message}"
  end
  
  begin
    decoded = model_class.decode_id(id)
    result = model_class.find(decoded)
    puts "ObfuscatesId: #{result.id}"
  rescue => e
    puts "ObfuscatesId failed: #{e.message}"
  end
  
  begin
    result = model_class.find_by_any_id(id)
    puts "DualIdSupport: #{result.id}"
  rescue => e
    puts "DualIdSupport failed: #{e.message}"
  end
end
```

## Future Enhancements

### Performance Optimization
- **Caching**: Cache slug → ID mappings for frequently accessed resources
- **Indexing**: Ensure proper database indexes on slug columns
- **Query Optimization**: Monitor and optimize slug-based lookups

### Extended Features
- **API Versioning**: Support different ID formats in different API versions
- **Admin Preferences**: Allow admins to choose ID format for their workflows
- **Analytics**: Track usage patterns of different ID formats

### Monitoring
- **Error Tracking**: Monitor decode failures and invalid ID attempts
- **Performance Metrics**: Track lookup times and success rates
- **Security Monitoring**: Alert on potential enumeration attacks

## Conclusion

This dual ID implementation successfully resolves the conflict between FriendlyId and Bullet Train's ObfuscatesId while providing:

✅ **SEO-friendly public URLs** with human-readable slugs  
✅ **Secure admin interfaces** with obfuscated IDs  
✅ **Backward compatibility** with existing Bullet Train patterns  
✅ **Robust error handling** preventing application crashes  
✅ **Clear separation of concerns** between public and admin contexts  

The solution maintains the security benefits of ID obfuscation while enabling the user experience benefits of friendly URLs, providing a production-ready foundation for the Backstage Pass marketplace platform.