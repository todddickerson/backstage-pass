# Deployment Guide

This guide covers deploying Backstage Pass to various platforms and environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Railway Deployment](#railway-deployment)
- [Heroku Deployment](#heroku-deployment)
- [Environment Variables](#environment-variables)
- [Database Setup](#database-setup)
- [Background Jobs](#background-jobs)
- [SSL & Domain Setup](#ssl--domain-setup)
- [Monitoring & Logging](#monitoring--logging)
- [Scaling Guidelines](#scaling-guidelines)

## Prerequisites

Before deploying, ensure you have:

1. **External Service Accounts**
   - Stripe account with API keys
   - LiveKit cloud account or self-hosted instance
   - GetStream.io account
   - Email service (Postmark/SendGrid)

2. **Storage Setup**
   - AWS S3 bucket or compatible storage
   - CDN (CloudFlare/CloudFront) optional but recommended

3. **Domain Name**
   - Production domain configured
   - SSL certificate (auto-provided by most platforms)

## Railway Deployment

Railway is the recommended platform for quick deployment with excellent DX.

### Initial Setup

1. **Install Railway CLI**
```bash
# macOS/Linux
curl -fsSL https://railway.app/install.sh | sh

# Or with npm
npm install -g @railway/cli
```

2. **Login and Create Project**
```bash
railway login
railway init
```

3. **Configure Services**
```bash
# Add PostgreSQL
railway add --plugin postgresql

# Add Redis
railway add --plugin redis
```

### Railway Configuration

Create `railway.toml`:

```toml
[build]
builder = "NIXPACKS"
buildCommand = "bundle install && yarn install && rake assets:precompile"

[deploy]
startCommand = "rake db:migrate && bin/rails server -b 0.0.0.0 -p $PORT"
healthcheckPath = "/health"
healthcheckTimeout = 30

[[services]]
name = "web"
type = "web"

[[services]]
name = "worker"
type = "worker"
startCommand = "bundle exec sidekiq"
```

### Deploy to Railway

```bash
# Deploy from local
railway up

# Deploy from GitHub
railway link  # Link to GitHub repo
railway up    # Triggers deployment
```

### Railway Environment Variables

Set in Railway dashboard or CLI:

```bash
railway variables set RAILS_MASTER_KEY=your_master_key
railway variables set DATABASE_URL=${{Postgres.DATABASE_URL}}
railway variables set REDIS_URL=${{Redis.REDIS_URL}}
railway variables set STRIPE_SECRET_KEY=sk_live_...
railway variables set LIVEKIT_API_KEY=...
railway variables set LIVEKIT_API_SECRET=...
railway variables set GETSTREAM_API_KEY=...
railway variables set GETSTREAM_API_SECRET=...
```

### Railway Custom Domain

```bash
# Add custom domain
railway domain add backstagepass.app

# Update DNS records
# Add CNAME: @ -> your-app.railway.app
```

## Heroku Deployment

### Initial Setup

1. **Install Heroku CLI**
```bash
# macOS
brew tap heroku/brew && brew install heroku

# Ubuntu/Debian
curl https://cli-assets.heroku.com/install.sh | sh
```

2. **Create Heroku App**
```bash
heroku create backstagepass-production
```

3. **Add Buildpacks**
```bash
heroku buildpacks:set heroku/ruby
heroku buildpacks:add --index 1 heroku/nodejs
```

### Heroku Add-ons

```bash
# PostgreSQL
heroku addons:create heroku-postgresql:standard-0

# Redis
heroku addons:create heroku-redis:premium-0

# Scheduler for cron jobs
heroku addons:create scheduler:standard
```

### Procfile Configuration

Create `Procfile`:

```procfile
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: rake db:migrate
```

### Deploy to Heroku

```bash
# Deploy from Git
git push heroku main

# Or using GitHub integration
heroku git:remote -a backstagepass-production
git push heroku main
```

### Heroku Environment Variables

```bash
# Set Rails master key
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)

# External services
heroku config:set STRIPE_SECRET_KEY=sk_live_...
heroku config:set LIVEKIT_API_KEY=...
heroku config:set LIVEKIT_API_SECRET=...
heroku config:set LIVEKIT_WS_URL=wss://...
heroku config:set GETSTREAM_API_KEY=...
heroku config:set GETSTREAM_API_SECRET=...

# Email service
heroku config:set POSTMARK_API_TOKEN=...
heroku config:set DEFAULT_FROM_EMAIL=support@backstagepass.app

# Storage
heroku config:set AWS_ACCESS_KEY_ID=...
heroku config:set AWS_SECRET_ACCESS_KEY=...
heroku config:set AWS_BUCKET=backstagepass-production
heroku config:set AWS_REGION=us-east-1
```

## Environment Variables

### Required Variables

```bash
# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=<from config/master.key>
RAILS_LOG_TO_STDOUT=enabled
RAILS_SERVE_STATIC_FILES=enabled

# Database
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# Redis
REDIS_URL=redis://user:pass@host:6379/0
SIDEKIQ_REDIS_URL=redis://user:pass@host:6379/1

# Application
SECRET_KEY_BASE=<generate with: rails secret>
BASE_URL=https://backstagepass.app

# External Services
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_live_...

LIVEKIT_API_KEY=...
LIVEKIT_API_SECRET=...
LIVEKIT_WS_URL=wss://your-livekit-server.com

GETSTREAM_API_KEY=...
GETSTREAM_API_SECRET=...
GETSTREAM_APP_ID=...

# Email
POSTMARK_API_TOKEN=...
DEFAULT_FROM_EMAIL=noreply@backstagepass.app
SUPPORT_EMAIL=support@backstagepass.app

# Storage (S3 or compatible)
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_BUCKET=backstagepass-production
AWS_REGION=us-east-1

# Optional
SENTRY_DSN=https://...@sentry.io/...
SKYLIGHT_AUTHENTICATION=...
NEW_RELIC_LICENSE_KEY=...
```

### Security Variables

```bash
# Content Security Policy
CSP_REPORT_URI=https://backstagepass.report-uri.com/r/d/csp/enforce

# Session Security
SESSION_TIMEOUT=3600
SECURE_COOKIES=true

# Rate Limiting
RACK_ATTACK_ENABLED=true
THROTTLE_LIMIT=100
THROTTLE_PERIOD=60
```

## Database Setup

### PostgreSQL Configuration

```yaml
# config/database.yml (production)
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV['DATABASE_URL'] %>
  
  # Connection pooling for high traffic
  pool: 25
  checkout_timeout: 5
  reaping_frequency: 10
  
  # Statement timeout to prevent long queries
  variables:
    statement_timeout: '10s'
```

### Database Migrations

```bash
# Run migrations on deploy
rails db:migrate

# Seed initial data (be careful in production!)
rails db:seed

# Create read replica (Heroku)
heroku addons:create heroku-postgresql:standard-0 --follow DATABASE_URL --as DATABASE_FOLLOWER
```

### Database Backups

```bash
# Heroku automated backups
heroku pg:backups:schedules --at "02:00 America/New_York"

# Manual backup
heroku pg:backups:capture

# Railway backups (automatic daily)
# Configure in Railway dashboard
```

## Background Jobs

### Sidekiq Configuration

```yaml
# config/sidekiq.yml
:concurrency: 10
:timeout: 25

:queues:
  - [critical, 6]
  - [default, 4]
  - [mailers, 3]
  - [low, 2]

production:
  :concurrency: 20
```

### Sidekiq Web UI

```ruby
# config/routes.rb
require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end
end
```

### Scheduled Jobs

```bash
# Heroku Scheduler
heroku addons:create scheduler:standard

# Add jobs in Heroku dashboard:
# - rails backstage:daily_digest (Daily at 9am)
# - rails backstage:cleanup_expired (Every hour)
# - rails backstage:calculate_analytics (Every 6 hours)
```

## SSL & Domain Setup

### CloudFlare Setup (Recommended)

1. **Add Site to CloudFlare**
   - Add domain to CloudFlare
   - Update nameservers at registrar

2. **Configure DNS**
```
Type    Name    Value                   Proxy
A       @       Your-Server-IP          ✓
CNAME   www     @                       ✓
CNAME   api     your-app.railway.app    ✓
```

3. **SSL Settings**
   - SSL/TLS Mode: Full (strict)
   - Always Use HTTPS: On
   - HSTS: Enabled
   - Minimum TLS: 1.2

### Let's Encrypt (Self-hosted)

```bash
# Install certbot
sudo apt-get install certbot

# Generate certificate
sudo certbot certonly --webroot -w /var/www/backstagepass -d backstagepass.app

# Auto-renewal
sudo certbot renew --dry-run
```

## Monitoring & Logging

### Application Monitoring

```ruby
# Gemfile
group :production do
  gem 'sentry-ruby'     # Error tracking
  gem 'sentry-rails'
  gem 'skylight'        # Performance monitoring
  gem 'newrelic_rpm'    # APM
end
```

### Sentry Configuration

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 0.1
  config.profiles_sample_rate = 0.1
  
  # Filter sensitive data
  config.before_send = lambda do |event, hint|
    event.request.cookies = {}
    event.request.data.delete('password')
    event
  end
end
```

### Logging Setup

```ruby
# config/environments/production.rb
config.log_level = :info
config.log_tags = [:request_id]

# Use lograge for cleaner logs
config.lograge.enabled = true
config.lograge.custom_options = lambda do |event|
  {
    user_id: event.payload[:user_id],
    team_id: event.payload[:team_id],
    ip: event.payload[:ip]
  }
end
```

### Health Checks

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def show
    checks = {
      database: check_database,
      redis: check_redis,
      sidekiq: check_sidekiq
    }
    
    if checks.values.all?
      render json: { status: 'healthy', checks: checks }
    else
      render json: { status: 'unhealthy', checks: checks }, status: :service_unavailable
    end
  end
  
  private
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue
    false
  end
  
  def check_redis
    Redis.current.ping == 'PONG'
  rescue
    false
  end
  
  def check_sidekiq
    Sidekiq::ProcessSet.new.size > 0
  rescue
    false
  end
end
```

## Scaling Guidelines

### Horizontal Scaling

```bash
# Railway
railway scale --replicas 3

# Heroku
heroku ps:scale web=3 worker=2
```

### Database Scaling

1. **Read Replicas**
   - Offload read queries
   - Geographic distribution
   - Failover capability

2. **Connection Pooling**
```ruby
# Use PgBouncer
DATABASE_URL=postgres://user:pass@pgbouncer:6432/db

# Configure in database.yml
production:
  pool: 5  # Per process
  checkout_timeout: 3
```

### Caching Strategy

1. **Redis Configuration**
```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 1.hour,
  namespace: 'cache',
  pool_size: 5,
  pool_timeout: 5
}
```

2. **CDN for Assets**
```ruby
# config/environments/production.rb
config.action_controller.asset_host = 'https://cdn.backstagepass.app'
```

### Performance Optimization

1. **Database Indexes**
```ruby
# Critical indexes for performance
add_index :experiences, [:space_id, :created_at]
add_index :streams, [:status, :scheduled_at]
add_index :access_grants, [:user_id, :expires_at]
```

2. **Background Job Optimization**
```yaml
# config/sidekiq.yml
:concurrency: 25  # Increase for more workers
:queues:
  - [critical, 10]  # Higher priority
  - [default, 5]
  - [low, 1]
```

3. **Auto-scaling Rules**
```yaml
# Railway.toml
[autoscaling]
enabled = true
min = 1
max = 10
targetCPU = 70
targetMemory = 80
```

## Deployment Checklist

### Pre-deployment

- [ ] All tests passing
- [ ] Security audit complete (`bundle audit`)
- [ ] Database migrations reviewed
- [ ] Environment variables set
- [ ] SSL certificate ready
- [ ] DNS configured
- [ ] Backup strategy defined

### Deployment

- [ ] Deploy to staging first
- [ ] Run database migrations
- [ ] Clear cache if needed
- [ ] Verify background jobs running
- [ ] Check error tracking working
- [ ] Test critical paths

### Post-deployment

- [ ] Monitor error rates
- [ ] Check performance metrics
- [ ] Verify email delivery
- [ ] Test payment processing
- [ ] Confirm streaming works
- [ ] Review logs for issues
- [ ] Update status page

## Troubleshooting

### Common Issues

**Asset Compilation Fails**
```bash
# Clear cache and retry
rails assets:clobber
rails assets:precompile
```

**Database Connection Issues**
```bash
# Check connection
rails db:migrate:status

# Reset connection pool
heroku pg:killall
```

**Memory Issues**
```ruby
# config/puma.rb
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

preload_app!

before_fork do
  ActiveRecord::Base.connection_pool.disconnect!
end

on_worker_boot do
  ActiveRecord::Base.establish_connection
end
```

## Support

For deployment assistance:
- Railway: [railway.app/help](https://railway.app/help)
- Heroku: [help.heroku.com](https://help.heroku.com)
- GitHub Issues: [github.com/backstagepass/issues](https://github.com/backstagepass/issues)

---

Remember: Always test deployments in staging before production!