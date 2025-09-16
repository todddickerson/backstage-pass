# Current Task Context

## 🎯 Working on Issue #6

### Title: STORY 4: Waitlist Management - Manual Approval System

### Description:
**User Story**: As a creator I want to review and approve waitlist applications so that I can control who gets access

**Acceptance Criteria:**
- [ ] Can view pending waitlist entries
- [ ] Can see applicant answers to custom questions
- [ ] Can approve or reject applications one by one
- [ ] Approved users receive email with access instructions
- [ ] Can see history of approved/rejected applications

**Technical Requirements:**
- WaitlistEntry model with status enum (NAMESPACED: AccessPasses::WaitlistEntry)
- Account::WaitlistEntriesController
- Email notifications on approval
- Manual approval only (no bulk for MVP)

**Super Scaffold Commands:**
```bash
# FIRST: Validate namespacing
ruby .claude/validate-namespacing.rb "rails generate super_scaffold AccessPasses::WaitlistEntry AccessPass,User ..."

# Create WaitlistEntry model
rails generate super_scaffold AccessPasses::WaitlistEntry AccessPass,User email:email_field answers:json_field status:options{pending,approved,rejected}
```

### Branch: issue-6

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
bin/gh-complete 6 "PR title describing changes"
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
*Context generated at: Tue Sep 16 14:56:15 EDT 2025*
