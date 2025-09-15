# Current Task Context

## 🎯 Working on Issue #1

### Title: Phase 1.1: Create core marketplace models (Space, Experience, AccessPass)

### Description:
## Phase 1.1: Core Marketplace Models

Create the foundational models for the Backstage Pass marketplace platform using Bullet Train's super_scaffold.

### Models to Create:

1. **Space** (belongs to Team)
   - name:text_field
   - description:trix_editor  
   - slug:text_field
   - published:boolean
   - settings:json (for welcome_message, brand_color, etc.)

2. **Experience** (belongs to Space)
   - name:text_field
   - description:trix_editor
   - experience_type:options{live_stream,course,community,consultation,digital_product}
   - access_model:options{one_time,subscription,lifetime}
   - price_cents:number_field

3. **AccessPass** (polymorphic purchasable)
   - user:belongs_to
   - purchasable:polymorphic (Space or Experience)
   - status:options{active,expired,cancelled,refunded}
   - expires_at:date_and_time_field

### Requirements:
- Use Bullet Train's super_scaffold for all models
- Follow NAMESPACING_CONVENTIONS.md (no namespace for primary subjects)
- Preserve 🚅 magic comments
- Add proper validations and associations
- Include monetization with monetize gem

### Acceptance Criteria:
- [ ] Space model created with proper Team association
- [ ] Experience model created with Space association  
- [ ] AccessPass model created with polymorphic purchasable
- [ ] All migrations run successfully
- [ ] Basic validations in place
- [ ] Can create records via Rails console

### Priority: Critical
This is the foundation for all marketplace functionality.

**AI Instructions: Use super_scaffold and follow Bullet Train conventions strictly.**

### Branch: issue-1

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
bin/gh-complete 1 "PR title describing changes"
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
*Context generated at: Mon Sep 15 14:16:58 EDT 2025*
