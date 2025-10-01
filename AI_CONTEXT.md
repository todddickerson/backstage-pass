# Current Task Context

## 🎯 Working on Issue #50

### Title: [CRITICAL] Test Suite Health & Stabilization

### Description:
## Problem
Test suite status unknown - full test run times out after 2 minutes. Only payment tests (65) verified passing. Cannot confidently deploy without knowing test health.

## Required Work
- [ ] Run test suite in batches (models, controllers, integration)
- [ ] Document current pass/fail rate
- [ ] Fix failing tests systematically
- [ ] Achieve 80%+ pass rate
- [ ] Document coverage gaps

## Success Criteria
- [ ] Full test suite runs in <5 minutes
- [ ] 80%+ tests passing
- [ ] All critical paths have test coverage
- [ ] Zero test timeouts

## Priority
🔴 **CRITICAL** - Cannot deploy without verified test suite

## Estimated Effort
2-3 days

## Dependencies
Blocks production deployment

### Branch: issue-50

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
bin/gh-complete 50 "PR title describing changes"
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
*Context generated at: Wed Oct  1 08:27:42 EDT 2025*
