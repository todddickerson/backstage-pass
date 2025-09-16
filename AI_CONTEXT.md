# Current Task Context

## 🎯 Working on Issue #18

### Title: STORY 14: Production Deployment - Heroku/Railway Setup & Configuration

### Description:
**User Story**: As a platform operator I want the application deployed to production so that users can access it

**Acceptance Criteria:**
- [ ] Application deployed to Heroku/Railway
- [ ] PostgreSQL database configured
- [ ] Redis configured for ActionCable & Sidekiq
- [ ] Background job processing working
- [ ] SSL certificates configured
- [ ] Custom domain setup
- [ ] CDN for assets (Cloudflare)
- [ ] Error tracking (Honeybadger/Sentry)
- [ ] Application monitoring
- [ ] Backup strategy implemented

**Infrastructure Checklist:**

### Core Services:
- [ ] Web dynos/containers scaled appropriately
- [ ] Worker dynos for Sidekiq
- [ ] PostgreSQL with connection pooling
- [ ] Redis for caching and ActionCable
- [ ] File storage (S3/R2 for uploads)

### External Services:
- [ ] LiveKit server configured
- [ ] Mux account for video distribution
- [ ] GetStream.io for chat
- [ ] Stripe webhooks configured
- [ ] SendGrid/Postmark for emails

### Environment Variables:
```yaml
RAILS_MASTER_KEY: [from config/master.key]
DATABASE_URL: [auto-provided]
REDIS_URL: [auto-provided]
BASE_URL: https://backstagepass.app

# LiveKit
LIVEKIT_API_KEY: xxx
LIVEKIT_API_SECRET: xxx
LIVEKIT_HOST: wss://xxx

# Mux
MUX_TOKEN_ID: xxx
MUX_TOKEN_SECRET: xxx

# GetStream
GETSTREAM_API_KEY: xxx
GETSTREAM_API_SECRET: xxx

# Stripe
STRIPE_PUBLISHABLE_KEY: pk_live_xxx
STRIPE_SECRET_KEY: sk_live_xxx
STRIPE_WEBHOOK_SECRET: whsec_xxx

# Email
SENDGRID_API_KEY: xxx
```

### Security:
- [ ] Secure headers configured
- [ ] CORS properly configured
- [ ] Rate limiting implemented
- [ ] DDoS protection (Cloudflare)
- [ ] Secrets rotated from development

### Performance:
- [ ] Database indexes optimized
- [ ] N+1 queries eliminated (Bullet gem)
- [ ] CDN configured for assets
- [ ] Image optimization pipeline
- [ ] Caching strategy implemented

### Monitoring:
- [ ] Application Performance Monitoring (APM)
- [ ] Error tracking (Honeybadger/Sentry)
- [ ] Uptime monitoring
- [ ] Log aggregation
- [ ] Custom metrics dashboard

### Deployment Process:
- [ ] GitHub Actions CI/CD pipeline
- [ ] Automated testing before deploy
- [ ] Database migration strategy
- [ ] Zero-downtime deployments
- [ ] Rollback procedure documented

### Branch: issue-18

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
bin/gh-complete 18 "PR title describing changes"
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
*Context generated at: Tue Sep 16 15:49:39 EDT 2025*
