# Current Task Context

## 🎯 Working on Issue #55

### Title: [MEDIUM] Analytics Data Collection & Dashboard

### Description:
## Problem
Analytics system incomplete. Creator dashboard needs basic metrics:
- Total revenue unknown
- Active pass count unknown  
- Stream viewer metrics unknown
- Data collection job not running

## Required Work

### Data Collection
- [ ] Implement daily snapshot background job
- [ ] Collect revenue metrics (from Billing::Purchase)
- [ ] Count active access passes
- [ ] Track stream viewer counts
- [ ] Setup counter caches on models

### Dashboard Implementation
- [ ] Display total revenue
- [ ] Display active pass count
- [ ] Show recent streams list
- [ ] Show viewer engagement metrics
- [ ] Simple charts/graphs (optional)

### Background Jobs
- [ ] Create `Analytics::DailySnapshotJob`
- [ ] Schedule job to run daily
- [ ] Test job execution

## Success Criteria
- [ ] Dashboard shows accurate revenue
- [ ] Dashboard shows pass counts
- [ ] Dashboard shows stream metrics
- [ ] Data updates daily
- [ ] No performance impact

## Files to Update
- `app/controllers/account/analytics_controller.rb`
- `app/models/analytics/daily_snapshot.rb`
- `app/jobs/analytics/daily_snapshot_job.rb` (create)
- `app/views/account/analytics/`

## Estimated Effort
2 days

## Priority
Medium - Nice to have but not critical for launch

### Branch: issue-55

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
bin/gh-complete 55 "PR title describing changes"
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
*Context generated at: Wed Oct  1 12:19:22 EDT 2025*
