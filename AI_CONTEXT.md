# Current Task Context

## 🎯 Working on Issue #5

### Title: STORY 7: Access Pass Purchase - Stripe Elements Integration

### Description:
**User Story**: As a viewer I want to purchase an Access Pass so that I can access exclusive content

**Acceptance Criteria:**
- [ ] Can click "Get Access" on any Access Pass
- [ ] Complete purchase with credit card (Stripe Elements - NOT Checkout)
- [ ] Immediately redirected to purchased content
- [ ] Receive email confirmation
- [ ] Custom UI with Stripe Elements (not hosted checkout)

**Technical Requirements:**
- Stripe Elements integration (custom checkout UI)
- Purchase model for transactions (NAMESPACED: Billing::Purchase)
- Automatic AccessPass activation
- Email notifications

**Note**: Passwordless auth moved to Phase 2 per user request - use standard Devise for now

**Super Scaffold Commands:**
```bash
# FIRST: Validate namespacing
ruby .claude/validate-namespacing.rb "rails generate super_scaffold Billing::Purchase AccessPass,User ..."

# Create Purchase model
rails generate super_scaffold Billing::Purchase AccessPass,User amount:number_field stripe_charge_id:text_field
```

### Branch: issue-5

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
bin/gh-complete 5 "PR title describing changes"
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
*Context generated at: Tue Sep 16 10:38:45 EDT 2025*
