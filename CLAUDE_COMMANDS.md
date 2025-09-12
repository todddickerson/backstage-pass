# Claude Code Command Reference - Backstage Pass

## 🎯 Super Scaffold Commands (ALWAYS USE THESE!)

### Basic Super Scaffold Syntax

```bash
# Basic syntax
rails generate super_scaffold ModelName ParentModel field1:field_type field2:field_type [options]

# Parent MUST be either:
# - Team (for top-level models)
# - Another model that belongs to Team
```

### Field Types Reference

```bash
# Text Fields
name:text_field           # Single line text input
slug:text_field           # URL-friendly identifier
email:email_field         # Email with validation
url:text_field           # URL input

# Rich Content
description:trix_editor   # Rich text editor (recommended)
content:text_area        # Plain multiline text

# Numbers
price:number_field       # Integer
amount:number_field      # Decimal
max_participants:number_field

# Dates & Times
starts_at:date_field     # Date only
scheduled_for:date_and_time_field  # DateTime picker
expires_at:date_and_time_field

# Booleans
active:boolean           # Checkbox
featured:boolean         # Yes/No toggle

# Associations
user:references          # belongs_to relationship
team:references          # belongs_to (usually automatic)

# Special Fields
status:options{draft,published,archived}  # Dropdown select
type:options{live_stream,course,community}  # Multiple choice
roles:multiple_option{admin,editor,viewer}  # Multiple select checkboxes

# File Uploads
avatar:image             # Image upload
attachment:file          # Any file upload

# JSON/JSONB
settings:json            # JSON data field
metadata:jsonb           # Binary JSON (PostgreSQL)
```

### Super Scaffold Options

```bash
# Sidebar icon (from Tabler Icons)
--sidebar="ti-building-store"    # Building icon
--sidebar="ti-broadcast"         # Broadcast icon
--sidebar="ti-ticket"           # Ticket icon
--sidebar="ti-users"            # Users icon
--sidebar="ti-video"            # Video icon

# Skip certain generations
--skip-migration                # Don't create migration
--skip-controller               # Don't create controller
--skip-model                   # Don't create model
--skip-views                   # Don't create views
--skip-api                    # Don't create API endpoints
--skip-routes                  # Don't add routes

# Parent specification
--parent=Team                  # Explicitly set parent
--parent=Space                 # For nested resources
```

### Complete Examples

```bash
# 1. Space (marketplace storefront)
rails generate super_scaffold Space Team \
  name:text_field \
  slug:text_field \
  description:trix_editor \
  status:options{draft,published,archived} \
  base_price_cents:number_field \
  cover_image:image \
  settings:json \
  --sidebar="ti-building-store"

# 2. Experience (what users buy access to)
rails generate super_scaffold Experience Space \
  name:text_field \
  description:trix_editor \
  experience_type:options{live_stream,course,community,consultation} \
  access_model:options{one_time,subscription,lifetime} \
  price_cents:number_field \
  max_participants:number_field \
  starts_at:date_and_time_field \
  ends_at:date_and_time_field \
  featured:boolean \
  --sidebar="ti-ticket"

# 3. AccessPass (purchase record)
rails generate super_scaffold AccessPass Team \
  user:references \
  purchasable_type:text_field \
  purchasable_id:number_field \
  status:options{active,expired,cancelled,refunded} \
  price_paid_cents:number_field \
  expires_at:date_and_time_field \
  metadata:json \
  --sidebar="ti-key"

# 4. Stream (live streaming session)
rails generate super_scaffold Stream Experience \
  title:text_field \
  description:trix_editor \
  room_name:text_field \
  status:options{scheduled,live,ended} \
  distribution_mode:options{livekit_only,hybrid_mux} \
  scheduled_for:date_and_time_field \
  started_at:date_and_time_field \
  ended_at:date_and_time_field \
  host:references \
  recording_enabled:boolean \
  chat_enabled:boolean \
  viewer_count:number_field \
  --sidebar="ti-broadcast"

# After each super_scaffold:
rails db:migrate
```

## 🎨 Theme Management Commands

### Eject Theme (MUST DO FIRST!)

```bash
# Create new theme with ejected views
rake bullet_train:themes:light:eject[backstage_pass]

# If shell complains about brackets:
rake bullet_train:themes:light:eject\[backstage_pass\]

# Eject to default location (app/views/)
rake bullet_train:themes:light:eject

# Eject individual view interactively
bin/resolve --interactive shared/navigation
# Then select "Eject this view"

# Find source of any view
bin/resolve shared/forms/field

# List all theme components
ls app/views/themes/backstage_pass/
```

### Theme Customization

```ruby
# config/initializers/theme.rb
Rails.application.config.theme = "backstage_pass"

# Custom colors
Rails.application.config.theme_colors = {
  primary: "#6B46C1",     # Purple
  secondary: "#EC4899",   # Pink  
  success: "#10B981",
  danger: "#EF4444",
  warning: "#F59E0B",
  info: "#3B82F6"
}
```

## 🧪 Magic Test Commands

### Recording Tests

```bash
# Start recording a new test
MAGIC_TEST=1 rails test test/system/example_test.rb

# Run test with visual browser (debugging)
HEADLESS=false rails test test/system/ai_generated/feature_test.rb

# Save recording after successful test
SAVE_RECORDING=1 rails test test/system/ai_generated/feature_test.rb

# Generate test from saved recording
rake magic_test:from_recording[purchase_flow]

# Verify all AI-generated tests
rake magic_test:verify
```

### Magic Test Rake Tasks

```ruby
# lib/tasks/magic_test.rake
namespace :magic_test do
  # Generate test from browser interaction
  task :generate, [:name] => :environment
  
  # Create from recording
  task :from_recording, [:file] => :environment
  
  # Run all AI tests
  task :verify => :environment
  
  # Clean old recordings
  task :cleanup => :environment
end
```

### Test Structure

```ruby
require "application_system_test_case"

class FeatureTest < ApplicationSystemTestCase
  include MagicTest::Support  # ALWAYS include!
  
  setup do
    # Create test data
    magic_test.start_recording if ENV['RECORD_TEST']
  end
  
  test "user journey" do
    visit root_path
    
    magic_test.record_action do
      # Complex interactions here
      fill_in "Email", with: "test@example.com"
      click_button "Sign In"
    end
    
    assert_selector ".success"
    
    magic_test.save_recording("feature_name") if ENV['SAVE_RECORDING']
  end
end
```

## 🚀 Rails with Bullet Train Commands

### Database Commands

```bash
# Create and setup
rails db:create
rails db:migrate
rails db:seed

# Reset everything
rails db:reset  # drop, create, migrate, seed

# Check migration status
rails db:migrate:status

# Rollback
rails db:rollback
rails db:rollback STEP=3

# Create migration manually (rare)
rails generate migration AddFieldToModel field:type
```

### Bullet Train Specific

```bash
# Add OAuth provider
rails generate bullet_train:oauth:omniauth_provider google
rails generate bullet_train:oauth:omniauth_provider discord

# Generate API documentation
rake bullet_train:api:docs

# Add webhook endpoint
rails generate bullet_train:webhook:endpoint stripe

# Add locale/translations
rails generate bullet_train:locale es

# Resolve view source
bin/resolve shared/fields/text_field

# Interactive resolution
bin/resolve --interactive

# Override framework components
bin/override
```

## 📱 Hotwire Native Commands

### iOS Setup

```bash
# Generate iOS app
rails generate hotwire:native:ios

# Open in Xcode
cd ios
pod install
open BackstagePass.xcworkspace

# Build and run
xcodebuild -scheme BackstagePass -sdk iphonesimulator
```

### Android Setup

```bash
# Generate Android app
rails generate hotwire:native:android

# Build
cd android
./gradlew build

# Run on emulator
./gradlew installDebug
adb shell am start -n app.backstagepass/.MainActivity
```

## 🔧 Development Commands

### Server & Console

```bash
# Start development server
bin/dev  # Runs Rails + assets + jobs

# Rails console
rails console
rails c  # shortcut

# Database console
rails dbconsole
rails db  # shortcut

# Run specific server
rails server -b 0.0.0.0 -p 3000  # Accessible from network
```

### Testing

```bash
# Run all tests
rails test
bundle exec rspec  # if using RSpec

# Run specific test file
rails test test/models/space_test.rb

# Run specific test
rails test test/models/space_test.rb:15

# System tests with browser
rails test:system

# With coverage
COVERAGE=true rails test
```

### Background Jobs

```bash
# Run Sidekiq
bundle exec sidekiq

# Specific queues
bundle exec sidekiq -q default -q mailers -q active_storage_analysis

# Clear all jobs
rails console
Sidekiq::Queue.all.each(&:clear)
```

## 🏗️ Project Management Commands

### Claude-Specific Tasks

```bash
# Check current status
rake claude:status

# Mark task complete
rake claude:complete[task_name]

# Move to next task
rake claude:next

# Run verification
rake claude:check

# Run pre-flight checks
bash .claude/pre-flight.sh

# Verify setup
bash .claude/verify-setup.sh
```

### Git Workflow

```bash
# Feature branch
git checkout -b feature/streaming-integration

# Commit with message
git add .
git commit -m "Add LiveKit streaming integration"

# Push and create PR
git push -u origin feature/streaming-integration

# Merge to main
git checkout main
git merge feature/streaming-integration
```

## 📊 Production Commands

### Deployment

```bash
# Precompile assets
RAILS_ENV=production rails assets:precompile

# Run migrations
RAILS_ENV=production rails db:migrate

# Deploy with Capistrano
cap production deploy

# Rollback deployment
cap production deploy:rollback

# Rails console on production
RAILS_ENV=production rails console
```

### Monitoring

```bash
# Check logs
tail -f log/production.log

# Rails logs
rails log:clear

# Check running processes
ps aux | grep rails

# Memory usage
free -h

# Disk usage
df -h
```

## 🔍 Debugging Commands

### Finding Issues

```bash
# Check for N+1 queries
grep -r "SELECT" log/development.log | wc -l

# Find unused routes
rails routes | grep -v "GET\|POST\|PATCH\|PUT\|DELETE"

# Check for missing indexes
rails db:migrate:status | grep down

# Lint ERB templates
bundle exec erb_lint app/views/

# Check for security issues
bundle exec brakeman

# Run Rubocop
bundle exec rubocop
bundle exec rubocop -a  # Auto-fix
```

### Performance

```bash
# Profile boot time
ruby -r profile -e 'require "./config/environment"'

# Benchmark a piece of code
rails runner 'puts Benchmark.measure { 1000.times { Space.first } }'

# Memory profiling
bundle exec derailed bundle:mem
```

## 💡 Quick Aliases

Add these to your `.bashrc` or `.zshrc`:

```bash
# Backstage Pass project aliases
alias bp='cd ~/backstage-pass'
alias bpc='bp && rails console'
alias bps='bp && bin/dev'
alias bpt='bp && rails test'
alias bpm='bp && rails db:migrate'
alias bpss='bp && rails generate super_scaffold'
alias bpmt='bp && MAGIC_TEST=1 rails test'
alias bpstatus='bp && rake claude:status'
alias bpcheck='bp && bash .claude/pre-flight.sh'
```

## 🚨 Emergency Commands

```bash
# If something is broken:

# Reset database
rails db:drop db:create db:migrate db:seed

# Clear all caches
rails cache:clear
rails tmp:clear

# Reinstall dependencies
bundle install
yarn install

# Reset git to last commit
git reset --hard HEAD

# Find what changed
git diff
git status

# Check system dependencies
bundle exec rails doctor
```

## 📝 Remember

1. **ALWAYS eject theme first** before working on views
2. **ALWAYS use super_scaffold** for new models
3. **ALWAYS preserve 🚅 magic comments** in generated files
4. **ALWAYS include MagicTest::Support** in system tests
5. **NEVER use `rails generate model`** directly
6. **NEVER delete magic comments** (🚅) from models
7. **NEVER skip team context** in queries
8. **ALWAYS run migrations** after super_scaffold
9. **ALWAYS configure button options** in locale files
10. **ALWAYS use ownership chains** for nested resources (Model,Parent,Team)

---

*This is your complete command reference. When in doubt, check here first!*