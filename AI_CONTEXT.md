# Current Task Context

## 🎯 Working on Issue #36

### Title: [STORY 4] Live Streaming: LiveKit Integration

### Description:
## User Story
As a **creator**, I want to **host live streams for my paying audience** so that **I can deliver exclusive content**.

## Acceptance Criteria
- [ ] Can schedule a stream with title and description
- [ ] Can go live with webcam and screen share
- [ ] Can see viewer count and chat
- [ ] Can moderate chat (delete messages, ban users)
- [ ] Can end stream and it saves as recording
- [ ] Only users with valid Access Pass can view

## Technical Requirements
- Integrate LiveKit SDK for WebRTC streaming
- Update Stream model with LiveKit room management
- Create streaming UI with video controls
- Integrate GetStream.io chat (already has ChatRoom model)
- Add recording to Cloudflare R2 storage
- Create Account::StreamsController for creator streaming
- Create Account::ExperiencesController for viewer streaming

## Implementation Steps
1. Add livekit-server-sdk gem
2. Create LiveKit room creation service
3. Build streaming interface with Stimulus
4. Connect GetStream chat to streaming rooms
5. Add viewer access verification
6. Implement recording storage

## Dependencies
- LiveKit API credentials configured
- GetStream.io already integrated
- Stream model already exists (needs LiveKit fields)
- Requires AccessGrant for access verification

## Priority
High for Phase 1 MVP - core feature for live content delivery

### Branch: issue-36

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
bin/gh-complete 36 "PR title describing changes"
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
*Context generated at: Thu Sep 18 11:09:18 EDT 2025*
