# Current Task Context

## 🎯 Working on Issue #3

### Title: STORY 2: Access Pass Creation - Complex AccessPass with Experience Selection

### Description:
**User Story**: As a creator I want to create different tiers of access passes so that I can offer various pricing options

**Acceptance Criteria:**
- [ ] Can create multiple Access Passes per Space
- [ ] Can set pricing (free, one-time, monthly, yearly)
- [ ] Can select which Experiences are included in each pass
- [ ] Can set stock limits and expiration
- [ ] Can enable waitlist with custom questions
- [ ] Can preview sales page for each Access Pass

**Technical Requirements:**
- AccessPass model with complex pricing structure (NOT NAMESPACED - primary subject)
- AccessPassExperience join table (NOT NAMESPACED - bridge model) 
- Monetize gem for price fields
- Stripe Elements for payment processing

**Super Scaffold Commands:**
```bash
# FIRST: Validate namespacing
ruby .claude/validate-namespacing.rb "rails generate super_scaffold AccessPass Space ..."

# Create AccessPass
rails generate super_scaffold AccessPass Space name:text_field price:number_field pricing_type:options{free,one_time,monthly,yearly}

# Create join table
rails generate super_scaffold AccessPassExperience AccessPass,Space experience:belongs_to
```

### Branch: issue-3

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
bin/gh-complete 3 "PR title describing changes"
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
*Context generated at: Tue Sep 16 09:44:59 EDT 2025*
