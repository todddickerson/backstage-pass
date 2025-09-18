# Current Task Context

## 🎯 Working on Issue #43

### Title: [STORY 7] Space Discovery: Public Marketplace

### Description:
## User Story
As a **viewer**, I want to **discover interesting Spaces** so that **I can find content worth purchasing**.

## Acceptance Criteria
- [ ] Can browse public Space pages
- [ ] Can view creator profiles at /@username  
- [ ] Can see Space description and available Access Passes
- [ ] Can preview what's included in each Access Pass
- [ ] Can see pricing clearly displayed

## Technical Requirements
- Create public controllers outside authentication
- Implement SEO-friendly URLs with slugs
- Public space browsing at /explore
- Creator profile pages at /@username route
- Basic filtering (no advanced search yet)

## Implementation Tasks
1. Create Public::SpacesController for browsing
2. Add explore page with published spaces
3. Implement creator profile pages (/@username route)
4. Create public Space detail pages
5. Display Access Passes with pricing
6. Add basic filtering by category/price

## Routes Needed
```ruby
# Public marketplace routes
get '/explore', to: 'public/spaces#index'
get '/@:username', to: 'public/creators#show'
get '/:space_slug', to: 'public/spaces#show'
get '/:space_slug/:access_pass_slug', to: 'public/access_passes#show'
```

## Dependencies
- Space model with published scope
- Creators::Profile model for usernames
- AccessPass with pricing display
- No authentication required (public pages)

## Priority
High for Phase 1 MVP - enables content discovery and marketplace browsing

### Branch: issue-43

## 📋 Implementation Checklist:
- [ ] Review issue requirements above
- [ ] Check NAMESPACING_CONVENTIONS.md before creating models
- [ ] Run validation: `ruby .claude/validate-namespacing.rb "command"`
- [ ] Use super_scaffold for all new models
- [ ] Follow PUBLIC_ROUTES_ARCHITECTURE.md for routes
- [ ] Maintain team context where needed
- [ ] Write tests (Magic Test for UI, RSpec for models)
- [ ] Update documentation if needed

## 🔧 Common Commands:
```bash
# Validate namespacing
ruby .claude/validate-namespacing.rb "rails generate super_scaffold ModelName"

# Generate model
rails generate super_scaffold ModelName ParentModel field:type

# Run tests
rails test
rails test:system

# Check changes
git status
git diff

# When complete
bin/gh-complete 43 "PR title describing changes"
```

## 📚 Key Documentation:
- CLAUDE.md - Project instructions (MUST READ)
- NAMESPACING_CONVENTIONS.md - Model naming rules
- TEAM_SPACE_ARCHITECTURE.md - Team/Space relationship
- PUBLIC_ROUTES_ARCHITECTURE.md - Route structure
- AUTHENTICATION_PASSWORDLESS.md - Auth implementation

## 🚨 Important Notes:
- Public routes do NOT need team context
- Primary subjects (Space, Experience, AccessPass, Stream) should NOT be namespaced
- Supporting models should be namespaced (Creators::Profile, Billing::Purchase)
- Always validate namespacing before generating models

---
*Context generated at: Thu Sep 18 14:45:04 EDT 2025*
