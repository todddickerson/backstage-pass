# Backstage Pass - Task Tracker

## ✅ Setup Phase - COMPLETE
- [x] Clone Bullet Train starter repo 
- [x] Run bin/setup
- [x] **EJECT THEME** (rake bullet_train:themes:light:eject[backstage_pass])
- [x] Verify ejected views exist in app/views/themes/backstage_pass/
- [x] Install required gems
- [x] Theme configuration complete

## 📍 Current Status: Ready for Implementation

### Key Decisions Made:
- **Chat:** GetStream.io (NOT LiveKit data channels)
- **Mobile:** Hotwire Native 2025 patterns (<20 lines setup)
- **Routes:** Using /account/ namespace (no /m/ complexity)
- **Waitlist:** Manual approval only for MVP

### See Documentation:
- **[USER_SPECS_PHASE1.md](./USER_SPECS_PHASE1.md)** - 13 user stories defined
- **[ARCHITECTURE_DECISIONS.md](./ARCHITECTURE_DECISIONS.md)** - All technical decisions
- **[HOTWIRE_NATIVE_2025.md](./HOTWIRE_NATIVE_2025.md)** - Mobile patterns

## Phase 1: Web Platform (Weeks 1-4)

### Week 1: Core Models
- [ ] Create CreatorProfile model (NEW - not polymorphic)
- [ ] Super scaffold Space model
- [ ] Create AccessPass model (complex, with Experience selection)
- [ ] Create AccessPassExperience join table
- [ ] Super scaffold Experience model

### Week 2: Purchase Flow
- [ ] Implement passwordless auth (6-digit codes)
- [ ] Stripe Elements integration
- [ ] Public sales pages
- [ ] Waitlist application system

### Week 3: Streaming
- [ ] LiveKit video integration
- [ ] GetStream.io chat setup
- [ ] Access control verification
- [ ] Basic moderation tools

### Week 4: Polish
- [ ] Email notifications
- [ ] Basic analytics
- [ ] Error handling
- [ ] Production deployment

## Phase 1b: Mobile Apps (Week 5-5.5)
- [ ] iOS Hotwire Native setup (<20 lines!)
- [ ] Android Hotwire Native setup (<15 lines!)
- [ ] Path configuration
- [ ] Bridge components for LiveKit
- [ ] TestFlight & internal testing
