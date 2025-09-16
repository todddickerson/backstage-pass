# Current Task Context

## 🎯 Working on Issue #8

### Title: STORY 12: Native Video Streaming - LiveKit Mobile Integration

### Description:
**User Story**: As a mobile viewer I want to watch streams with native video players so that I get optimal performance and battery life

**Acceptance Criteria:**
- [ ] Native video player launches for streams
- [ ] Video continues in background (audio only)
- [ ] Picture-in-picture mode supported
- [ ] Screen rotation handled natively
- [ ] Low latency (<2 seconds)
- [ ] Adaptive bitrate for mobile networks

**Technical Requirements:**
- LiveKit iOS SDK integration
- LiveKit Android SDK integration
- JavaScript bridge for player control
- Native player UI components  
- Background audio permissions

**Bridge Components:**
- BridgeComponent pattern for video player
- Native/web communication for stream control
- Platform detection for web fallback

**Dependencies:**
```
# iOS Package.swift
.package(url: "https://github.com/livekit/client-sdk-swift", from: "2.0.0")

# Android build.gradle  
implementation 'io.livekit:livekit-android:2.0.0'
```

### Branch: issue-8

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
bin/gh-complete 8 "PR title describing changes"
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
*Context generated at: Tue Sep 16 13:48:45 EDT 2025*
