# Current Task Context

## 🎯 Working on Issue #4

### Title: STORY 3: Live Stream Hosting - Stream Model with LiveKit

### Description:
**User Story**: As a creator I want to host live streams for my paying audience so that I can deliver exclusive content

**Acceptance Criteria:**
- [ ] Can schedule a stream with title and description
- [ ] Can go live with webcam and screen share
- [ ] Can see viewer count and chat
- [ ] Can moderate chat (delete messages, ban users)
- [ ] Can end stream and it saves as recording
- [ ] Only users with valid Access Pass can view

**Technical Requirements:**
- LiveKit integration for WebRTC streaming (NOT GetStream.io for video)
- GetStream.io for chat functionality
- Stream model with status states (NOT NAMESPACED - primary subject)
- Recording to Cloudflare R2

**Super Scaffold Commands:**
```bash
# FIRST: Validate namespacing
ruby .claude/validate-namespacing.rb "rails generate super_scaffold Stream Experience ..."

# Create Stream model
rails generate super_scaffold Stream Experience title:text_field description:trix_editor scheduled_at:date_and_time_field status:options{scheduled,live,ended}
```

### Branch: issue-4

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
bin/gh-complete 4 "PR title describing changes"
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
*Context generated at: Tue Sep 16 13:21:33 EDT 2025*
