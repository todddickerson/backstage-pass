# Current Task Context

## 🎯 Working on Issue #52

### Title: [HIGH] Complete LiveKit Streaming Integration

### Description:
## Problem
LiveKit integration incomplete. Controllers and routes exist but end-to-end streaming unverified:
- Unknown if room creation works
- Unknown if token generation works
- Unknown if video player functional
- Unknown if screen sharing works
- Unknown if recordings save

## Required Work

### Creator Streaming
- [ ] Implement LiveKit room creation on stream start
- [ ] Generate creator access tokens
- [ ] Test webcam streaming
- [ ] Test screen sharing
- [ ] Verify recording to storage

### Viewer Streaming
- [ ] Generate viewer access tokens (with access verification)
- [ ] Implement video player frontend
- [ ] Test adaptive bitrate
- [ ] Test multiple concurrent viewers

### Testing
- [ ] End-to-end: Create → Go Live → Watch → End flow
- [ ] Multiple viewers concurrent test
- [ ] Network condition testing (3G, 4G, WiFi)
- [ ] Latency verification (<3 seconds target)

## Success Criteria
- [ ] Creator can go live with video + screen share
- [ ] Viewers with access can watch streams
- [ ] Video latency <3 seconds
- [ ] Recordings saved to storage
- [ ] Stream ends cleanly

## Files to Review
- `app/controllers/account/stream_viewing_controller.rb`
- `app/controllers/account/experiences_controller.rb`
- `app/controllers/public/experiences_controller.rb`
- `app/models/stream.rb`

## Estimated Effort
3-4 days

## Dependencies
- LiveKit credentials configured (DONE)
- Access control verified (issue #51)

### Branch: issue-52

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
bin/gh-complete 52 "PR title describing changes"
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
*Context generated at: Wed Oct  1 09:01:56 EDT 2025*
