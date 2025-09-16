# Production Deployment Checklist - Backstage Pass

## 🚂 Primary Deployment: Railway (MVP)

**Railway is our primary deployment platform for MVP** - it's simple, fast, and handles infrastructure automatically.

### Quick Railway Setup
1. **Connect GitHub**: Link this repo to Railway at https://railway.app
2. **Auto-deployment**: Railway deploys automatically on push to main
3. **Add services**: PostgreSQL and Redis from Railway marketplace
4. **Set environment variables**: Use Railway dashboard or CLI
5. **Custom domain**: Add your domain in Railway dashboard

### Railway CLI Commands
```bash
# Install CLI
npm install -g @railway/cli

# Login and link project
railway login
railway link

# Deploy manually
railway up

# Manage environment variables
railway variables set KEY=value

# View logs
railway logs

# Run Rails console
railway run rails console

# Database commands
railway run rails db:migrate
railway run rails db:seed
```

## 🐳 Alternative: Kamal 2 (Future/Production Scale)

See [Issue #23](https://github.com/todddickerson/backstage-pass/issues/23) for Kamal 2 evaluation.
Kamal 2 setup is included in this repo but not prioritized for MVP.

## 🔐 Environment Variables Required

### Core Rails Configuration
```bash
# Required - Get from config/master.key file
RAILS_MASTER_KEY=your-master-key-from-config

# Auto-provided by hosting platform
DATABASE_URL=postgresql://user:password@host:5432/dbname
REDIS_URL=redis://user:password@host:6379/0

# Application settings
BASE_URL=https://backstagepass.app
MARKETING_SITE_URL=https://backstagepass.app
RAILS_ENV=production
SECRET_KEY_BASE=generate-with-rails-secret

# Bullet Train specific (from config/application.yml)
APPLICATION_HOST=backstagepass.app
```

### 📹 LiveKit (Real-time Video Streaming)
**Account Setup**: https://livekit.io
1. Sign up for LiveKit Cloud account
2. Create a new project
3. Get API credentials from dashboard

```bash
LIVEKIT_API_KEY=APIxxxxxxxx
LIVEKIT_API_SECRET=secret-key-from-livekit
LIVEKIT_HOST=wss://your-project.livekit.cloud
```

### 🎬 Mux (Video Processing & HLS Distribution)
**Account Setup**: https://www.mux.com
1. Create Mux account
2. Go to Settings → Access Tokens
3. Create new token with "Mux Video" permissions

```bash
MUX_TOKEN_ID=your-mux-token-id
MUX_TOKEN_SECRET=your-mux-token-secret
```

### 💬 GetStream.io (Chat System)
**Account Setup**: https://getstream.io
1. Sign up for Stream account
2. Create a new app (select "Chat" product)
3. Get credentials from dashboard

```bash
GETSTREAM_API_KEY=your-stream-api-key
GETSTREAM_API_SECRET=your-stream-api-secret
GETSTREAM_APP_ID=your-app-id  # Optional but recommended
```

### 💳 Stripe (Payments)
**Account Setup**: https://stripe.com
1. Create Stripe account
2. Complete business verification
3. Get API keys from Developers → API keys
4. Set up webhook endpoint

```bash
# Production keys (starts with pk_live_ and sk_live_)
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxx
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxx

# For Stripe Connect (creator payouts)
STRIPE_CLIENT_ID=ca_xxxxxxxxxxxx

# Webhook secret (from webhook endpoint setup)
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxx
```

**Webhook Configuration**:
- Endpoint URL: `https://backstagepass.app/webhooks/stripe`
- Events to listen for:
  - `payment_intent.succeeded`
  - `payment_intent.failed`
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
  - `invoice.payment_succeeded`
  - `invoice.payment_failed`

### 📧 Email Service

#### Option 1: SendGrid (Recommended)
**Account Setup**: https://sendgrid.com
1. Create SendGrid account
2. Verify domain for sending
3. Create API key with "Mail Send" permissions

```bash
SENDGRID_API_KEY=SG.xxxxxxxxxxxx
SENDGRID_DOMAIN=backstagepass.app
```

#### Option 2: Postmark
**Account Setup**: https://postmarkapp.com
```bash
POSTMARK_API_TOKEN=xxxxxxxxxxxx
```

### 🗄️ File Storage

#### Option 1: AWS S3
**Account Setup**: https://aws.amazon.com
1. Create S3 bucket
2. Create IAM user with S3 access
3. Generate access keys

```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=secret...
AWS_REGION=us-east-1
AWS_BUCKET=backstagepass-production
```

#### Option 2: Cloudflare R2 (Recommended - no egress fees)
**Account Setup**: https://cloudflare.com
1. Enable R2 in Cloudflare dashboard
2. Create bucket
3. Generate API token

```bash
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_R2_ACCESS_KEY_ID=your-access-key
CLOUDFLARE_R2_SECRET_ACCESS_KEY=your-secret-key
CLOUDFLARE_R2_BUCKET=backstagepass-production
CLOUDFLARE_R2_ENDPOINT=https://your-account-id.r2.cloudflarestorage.com
```

### 🔍 Monitoring & Error Tracking

#### Honeybadger (Recommended)
**Account Setup**: https://www.honeybadger.io
```bash
HONEYBADGER_API_KEY=hbp_xxxxxxxxxxxx
```

#### OR Sentry
**Account Setup**: https://sentry.io
```bash
SENTRY_DSN=https://xxxx@sentry.io/xxxxx
```

### 📊 Application Performance Monitoring

#### New Relic
**Account Setup**: https://newrelic.com
```bash
NEW_RELIC_LICENSE_KEY=xxxxxxxxxxxx
NEW_RELIC_APP_NAME=backstage-pass-production
```

#### OR Scout APM
```bash
SCOUT_KEY=xxxxxxxxxxxx
SCOUT_NAME=backstage-pass-production
```

### 🔒 Security & Encryption

```bash
# Generate with: rails db:encryption:init
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=xxxxxxxxxxxx
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=xxxxxxxxxxxx
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=xxxxxxxxxxxx
```

### 📱 Push Notifications (Optional for Phase 2)

#### Firebase (for Android)
```bash
FIREBASE_SERVER_KEY=xxxxxxxxxxxx
```

#### Apple Push Notifications (for iOS)
```bash
APNS_PEM_PATH=/path/to/certificate.pem
APNS_ENVIRONMENT=production
```

## 🏗️ Infrastructure Services to Set Up

### 1. Hosting Platform

#### Option A: Railway (Recommended for MVP) ⭐
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and link project
railway login
railway link

# Deploy
railway up

# Add PostgreSQL and Redis from Railway marketplace
# Configure environment variables via Railway dashboard
```

**Why Railway for MVP:**
- ✅ Automatic deployments on git push
- ✅ Built-in PostgreSQL and Redis
- ✅ Automatic SSL certificates
- ✅ Simple environment variable management
- ✅ Preview environments for pull requests
- ✅ No DevOps overhead

#### Option B: Heroku (Alternative)
```bash
# Install Heroku CLI
heroku create backstage-pass-production

# Add buildpacks
heroku buildpacks:add heroku/nodejs
heroku buildpacks:add heroku/ruby

# Add PostgreSQL
heroku addons:create heroku-postgresql:standard-0

# Add Redis
heroku addons:create heroku-redis:premium-0

# Scale dynos
heroku ps:scale web=2 worker=1
```

#### Option C: Kamal 2 (Future/Scale)
See [Issue #23](https://github.com/todddickerson/backstage-pass/issues/23) for evaluation.
Best for high-traffic production with custom server management.

### 2. CDN Setup (Cloudflare)
1. Add domain to Cloudflare
2. Configure DNS
3. Enable:
   - SSL/TLS (Full mode)
   - Auto Minify (HTML, CSS, JS)
   - Brotli compression
   - Page Rules for caching
   - DDoS protection

### 3. Domain Configuration
```
A Record: @ → Your server IP
CNAME: www → @
MX Records: For email service
TXT Records: For domain verification (SendGrid, etc.)
```

## 📋 Pre-Deployment Checklist

### Database Setup
```bash
# Run migrations
rails db:migrate RAILS_ENV=production

# Seed initial data
rails db:seed RAILS_ENV=production

# Create database indexes for performance
rails db:migrate:status
```

### Asset Compilation
```bash
# Precompile assets
RAILS_ENV=production rails assets:precompile

# Clean old assets
RAILS_ENV=production rails assets:clean
```

### Security Checks
```bash
# Run security audit
bundle exec brakeman
bundle exec bundler-audit check

# Check for exposed secrets
git secrets --scan

# Ensure all secrets are in credentials
rails credentials:edit --environment production
```

## 🚀 Deployment Commands

### Initial Deploy (Heroku)
```bash
# Set all environment variables
heroku config:set RAILS_MASTER_KEY=xxx
heroku config:set LIVEKIT_API_KEY=xxx
# ... set all other vars

# Deploy
git push heroku main

# Run migrations
heroku run rails db:migrate

# Seed data
heroku run rails db:seed

# Check logs
heroku logs --tail
```

### GitHub Actions CI/CD
Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Production
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Heroku
        uses: akhileshns/heroku-deploy@v3.12.12
        with:
          heroku_api_key: ${{secrets.HEROKU_API_KEY}}
          heroku_app_name: "backstage-pass-production"
          heroku_email: "your-email@example.com"
```

## 🧪 Post-Deployment Testing

### Critical Paths to Test
1. User registration and login
2. Space creation
3. Access Pass purchase (use Stripe test mode first)
4. Stream creation and joining
5. Chat functionality
6. File uploads
7. Email notifications

### Load Testing
```bash
# Use Apache Bench
ab -n 1000 -c 100 https://backstagepass.app/

# Or use k6 for more complex scenarios
k6 run loadtest.js
```

## 🔄 Rollback Plan

### Heroku Rollback
```bash
# View releases
heroku releases

# Rollback to previous
heroku rollback

# Or rollback to specific version
heroku rollback v42
```

### Database Rollback
```bash
# Rollback last migration
heroku run rails db:rollback

# Rollback multiple migrations
heroku run rails db:rollback STEP=3
```

## 📊 Monitoring Setup

### Essential Metrics to Track
1. Response time (target < 200ms)
2. Error rate (target < 1%)
3. Database query time
4. Background job processing time
5. WebSocket connection count
6. Payment success rate

### Alerts to Configure
- Server error rate > 1%
- Response time > 500ms
- Database connections > 80%
- Disk usage > 90%
- Payment failures spike
- Background job queue > 1000

## 🎯 Launch Checklist

- [ ] All environment variables configured
- [ ] Database migrated and seeded
- [ ] SSL certificate active
- [ ] CDN configured
- [ ] Email sending verified
- [ ] Payment processing tested
- [ ] Streaming infrastructure tested
- [ ] Chat system functional
- [ ] Error tracking active
- [ ] Monitoring dashboards set up
- [ ] Backup system configured
- [ ] Security headers verified
- [ ] Rate limiting active
- [ ] GDPR/Privacy compliance checked
- [ ] Terms of Service published
- [ ] Support email configured

## 📞 Support Contacts

Keep these handy for launch day:
- LiveKit Support: support@livekit.io
- Mux Support: support@mux.com
- GetStream Support: support@getstream.io
- Stripe Support: https://support.stripe.com
- Heroku Support: https://help.heroku.com

## 🚨 Emergency Procedures

### High Load
1. Scale dynos immediately
2. Enable Cloudflare "I'm Under Attack" mode
3. Increase database connections
4. Disable non-critical features

### Payment Issues
1. Check Stripe dashboard for failures
2. Verify webhook is receiving events
3. Check logs for payment errors
4. Contact Stripe support if needed

### Streaming Issues
1. Check LiveKit server status
2. Verify API credentials
3. Check WebSocket connections
4. Fall back to Mux-only mode if needed

---

**Note**: This checklist is for the Phase 1 MVP. Additional services may be required for Phase 2 features like mobile push notifications, advanced analytics, etc.