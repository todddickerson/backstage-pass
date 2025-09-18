# Current Task Context

## 🎯 Working on Issue #35

### Title: [STORY 3] Purchase Flow: Stripe Integration & Checkout

### Description:
## User Story
As a **viewer**, I want to **purchase an Access Pass** so that **I can access exclusive content**.

## Acceptance Criteria
- [ ] Can click "Get Access" on any Access Pass
- [ ] If not logged in, enter email for passwordless auth
- [ ] Receive 6-digit code via email
- [ ] Complete purchase with credit card (Stripe Elements)
- [ ] Immediately redirected to purchased content
- [ ] Receive email confirmation

## Technical Requirements
- Create Billing::Purchase model (namespaced)
- Create AccessGrant model to track user access to passes
- Integrate Stripe Elements for payment processing
- Implement passwordless authentication with OTP
- Create Public::PurchasesController for checkout flow
- Create Account::AccessPassesController for managing purchases

## Implementation Steps
1. Add Pay gem and configure Stripe
2. Create Purchase and AccessGrant models
3. Build checkout flow with Stripe Elements
4. Add passwordless auth with email OTP
5. Create purchase confirmation emails
6. Add access verification to experiences

## Dependencies
- Stripe API keys configured
- Pay gem for Stripe integration
- Requires AccessPass model from Story 2

## Priority
Critical for Phase 1 MVP - monetization requires purchase flow

### Branch: issue-35

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
bin/gh-complete 35 "PR title describing changes"
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
*Context generated at: Thu Sep 18 10:35:04 EDT 2025*
