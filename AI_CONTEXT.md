# Current Task Context

## 🎯 Working on Issue #34

### Title: [STORY 2] Access Pass System: Products & Pricing

### Description:
## User Story
As a **creator**, I want to **create different tiers of access passes** so that **I can offer various pricing options**.

## Acceptance Criteria
- [ ] Can create multiple Access Passes per Space
- [ ] Can set pricing (free, one-time, monthly, yearly)
- [ ] Can select which Experiences are included in each pass
- [ ] Can set stock limits and expiration
- [ ] Can enable waitlist with custom questions
- [ ] Can preview sales page for each Access Pass

## Technical Requirements
- Create AccessPass model with complex pricing structure
- Create Experience model for content/streams
- Create AccessPassExperience join table (already exists, needs proper associations)
- Integrate money-rails gem for price fields
- Add pricing_type enum: [:free, :one_time, :monthly, :yearly]
- Add stock management fields

## Super Scaffold Commands
```bash
# Create Experience model
rails generate super_scaffold Experience Space,Team title:text_field description:trix_editor experience_type:buttons scheduled_at:date_and_time_field

# Create AccessPass model
rails generate super_scaffold AccessPass Space,Team title:text_field description:trix_editor pricing_type:buttons price_cents:number_field stock_limit:number_field expires_at:date_and_time_field waitlist_enabled:boolean

# Add associations in models
```

## Dependencies
- money-rails gem
- Requires Space model from Story 1

## Priority
Critical for Phase 1 MVP - core monetization feature

### Branch: issue-34

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
bin/gh-complete 34 "PR title describing changes"
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
*Context generated at: Thu Sep 18 09:58:44 EDT 2025*
