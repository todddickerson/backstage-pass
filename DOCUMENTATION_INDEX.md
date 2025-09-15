# Backstage Pass Documentation Index

## 📍 Current Active Documentation (Sept 2025)

### Primary Documents
1. **[USER_SPECS_PHASE1.md](./USER_SPECS_PHASE1.md)** - Complete Phase 1 specifications
   - 13 user stories with acceptance criteria
   - Technical implementation details
   - Timeline: 5.5 weeks total

2. **[ARCHITECTURE_DECISIONS.md](./ARCHITECTURE_DECISIONS.md)** - Technical architecture
   - AccessPass model design (complex, not polymorphic)
   - CreatorProfile model (new requirement)
   - GetStream.io for chat (decision made)
   - Deferred features documented

3. **[HOTWIRE_NATIVE_2025.md](./HOTWIRE_NATIVE_2025.md)** - Mobile implementation
   - Rails World 2025 patterns
   - <20 lines of setup code
   - BridgeComponent pattern
   - Path configuration approach

4. **[CLAUDE.md](./CLAUDE.md)** - AI assistant instructions
   - Bullet Train conventions
   - Super scaffolding patterns
   - Updated with latest decisions

### Workflow Documents
- **[CLAUDE_CODE_WORKFLOW.md](./CLAUDE_CODE_WORKFLOW.md)** - Development workflow
- **[QUICKSTART.md](./QUICKSTART.md)** - Quick reference guide
- **[TASKS.md](./TASKS.md)** - Current sprint tasks
- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Initial setup instructions

### Reference Documents
- **[CLAUDE_COMMANDS.md](./CLAUDE_COMMANDS.md)** - Command reference

## ⚠️ Deprecated Documentation

### Replaced Documents
- **[HOTWIRE_NATIVE.md](./HOTWIRE_NATIVE.md)** 
  - Status: DEPRECATED
  - Replaced by: HOTWIRE_NATIVE_2025.md
  - Reason: Outdated patterns from pre-Rails World 2025

### Resolved Documents
- **[CLARIFICATIONS_NEEDED.md](./CLARIFICATIONS_NEEDED.md)**
  - Status: RESOLVED/ARCHIVED
  - Answers in: ARCHITECTURE_DECISIONS.md
  - All questions have been answered

## 🚀 Implementation Order

1. **Start Here:** [USER_SPECS_PHASE1.md](./USER_SPECS_PHASE1.md)
2. **Architecture:** [ARCHITECTURE_DECISIONS.md](./ARCHITECTURE_DECISIONS.md)
3. **Mobile (Week 5):** [HOTWIRE_NATIVE_2025.md](./HOTWIRE_NATIVE_2025.md)

## Key Decisions Summary

### Technical Stack
- **Rails 8** + **Bullet Train** framework
- **GetStream.io** for chat (NOT LiveKit data channels)
- **LiveKit** for video streaming only
- **Hotwire Native** with 2025 patterns
- **Stripe Elements** for payments

### Architecture
- **CreatorProfile** model (outside Team context)
- **AccessPass** with Experience selection (not polymorphic)
- **/account/** namespace for member routes (not /m/)
- **Manual waitlist** approval for MVP

### Timeline
- **Phase 1:** Weeks 1-4 (Web platform)
- **Phase 1b:** Week 5-5.5 (Mobile apps)
- **Total:** 5.5 weeks to production

## Next Steps

```bash
# 1. Install dependencies
bundle add stream-chat-ruby livekit-server-sdk stripe money-rails hotwire-native-rails

# 2. Create first model
rails generate super_scaffold CreatorProfile User username:text_field bio:text_area

# 3. Follow USER_SPECS_PHASE1.md for implementation
```

---

Last Updated: September 15, 2025