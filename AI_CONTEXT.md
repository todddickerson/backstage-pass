# Current Task Context

## 🎯 Working on Issue #33

### Title: [STORY 1] Creator Onboarding: Profile & Space Setup

### Description:
## User Story
As a **creator**, I want to **set up my creator profile and first Space** so that **I can start selling access to my content**.

## Acceptance Criteria
- [ ] Can create creator profile with username (/@username route)
- [ ] Space auto-created when Team created (simplified UX)
- [ ] Can edit Space name, description, cover image
- [ ] Can set Space slug for public URL
- [ ] Can configure Space brand colors and welcome message
- [ ] Space has public sales page at /space-slug

## Technical Requirements
- Create Creators::Profile model with FriendlyId for username routing
- Create Space model that belongs_to :team (one per Team initially)
- Add Team after_create :create_default_space callback
- Space validates :team_id, uniqueness: true
- Create Public::SpacesController for sales pages
- Create Public::CreatorProfilesController for /@username routes

## Super Scaffold Commands
```bash
# Create namespaced Creator Profile
rails generate super_scaffold Creators::Profile User username:text_field bio:text_area avatar_url:text_field

# Create Space model
rails generate super_scaffold Space Team name:text_field slug:text_field description:trix_editor brand_color:color_field cover_image_url:text_field

# Add uniqueness validation and auto-creation callback
```

## Priority
Critical for Phase 1 MVP - creators need profiles and spaces to sell content

### Branch: issue-33

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
bin/gh-complete 33 "PR title describing changes"
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
*Context generated at: Thu Sep 18 09:53:42 EDT 2025*
