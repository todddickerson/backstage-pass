# Current Task Context

## 🎯 Working on Issue #9

### Title: GetStream.io Chat Integration - Real-time Chat System

### Description:
**Feature**: Integrate GetStream.io for robust chat functionality across web and mobile

**Requirements:**
- [ ] GetStream.io setup and configuration
- [ ] Chat rooms for each live stream
- [ ] Real-time messaging during streams
- [ ] Moderation tools for creators
- [ ] Mobile chat integration
- [ ] Message history and persistence

**Technical Implementation:**
- GetStream.io JavaScript SDK for web
- Native chat components for mobile
- Creator moderation interface
- Access control (only AccessPass holders can chat)

**Integration Points:**
- Stream model integration with chat rooms
- User authentication with GetStream tokens
- Mobile bridge for chat functionality

**Dependencies:**
```ruby
gem 'stream-chat-ruby'
```

**Environment Variables:**
```yaml
GETSTREAM_API_KEY: xxx
GETSTREAM_API_SECRET: xxx  
```

### Branch: issue-9

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
bin/gh-complete 9 "PR title describing changes"
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
*Context generated at: Tue Sep 16 13:16:03 EDT 2025*
