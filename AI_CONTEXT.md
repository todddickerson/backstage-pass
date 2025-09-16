# Current Task Context

## 🎯 Working on Issue #7

### Title: STORY 11: Mobile App Installation - Hotwire Native Setup

### Description:
**User Story**: As a viewer I want to download the Backstage Pass mobile app so that I can have a better streaming experience

**Acceptance Criteria:**
- [ ] Can install iOS app via TestFlight
- [ ] Can install Android app via internal testing
- [ ] App opens to Space discovery screen
- [ ] Can sign in with email
- [ ] Receives push notifications for streams

**Technical Requirements:**
- Hotwire Native iOS wrapper (Swift) - 2025 simplified approach
- Hotwire Native Android wrapper (Kotlin) - 2025 simplified approach  
- Push notification setup (Firebase/APNS)
- Native authentication bridge

**Implementation:**
- iOS: ~20 lines of code with 2025 patterns
- Android: ~15 lines of code with 2025 patterns
- Path configuration for both platforms

**Dependencies:**
```ruby
# Gemfile additions
gem 'hotwire-native-rails', '~> 1.0'
gem 'rpush', '~> 8.0'
gem 'device_detector', '~> 1.1'
```

### Branch: issue-7

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
bin/gh-complete 7 "PR title describing changes"
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
*Context generated at: Tue Sep 16 14:44:59 EDT 2025*
