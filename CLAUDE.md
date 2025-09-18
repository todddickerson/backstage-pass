# Important Notes:

## MCPs
- Utilize Perplexity MCP w/ deep research instead of Websearch standards to ensure answers are complete
- Utilize BrowserToolsMCP if you need to view my console
- Utilize PlaywrightMCP if needed to control a webbrowser or take screenshots

## Testing (https://bullettrain.co/docs/testing)
- bin/rails test (not rspec) 
    ``` 
        rails test 
        rails test:system
    ```
- standardrb --fix before commit (fix anything it can't auto fix)

### Fixing Broken Tests
1. Run Chrome in Non-Headless Mode
    When debugging tests, it's important to be able to see what Capybara is seeing. You can disable the headless browser mode by prefixing rails test like so:

    MAGIC_TEST=1 rails test
    When you run the test suite with MAGIC_TEST set in your environment like this, the browser will appear on your screen after the first Capybara test starts. (This may not be the first test that runs.) Be careful not to interact with the window when it appears, as sometimes your interactions can cause the test to fail needlessly.

2. Insert binding.pry.
    Open the failing test file and insert binding.pry right before the action or assertion that is causing the test to fail. After doing that, when you run the test, it will actually stop and open a debugging console while the browser is still open to the appropriate page where the test is beginning to fail. You can use this console and the open browser to try and figure out why the test is failing. When you're done, hit Control + D to exit the debugger and continue letting the test run. 

## Controllers
- Account:: Namespace controllers should be setting role specific accessible content utilizing `account_load_and_authorize_resource` so roles.yml gets used properly and team permissions
  - Additional checks / filters for access logic beyond that could be added after that 
  - ```
    Usage Example
      In a Bullet Train-style controller, you might see:

      ruby
      class Api::V1::DocumentsController < Api::V1::ApplicationController
        account_load_and_authorize_resource
        # RESTful actions: index, show, create, update, destroy, etc.
      end
      This ensures that only resources belonging to the current account are loaded, and permissions are checked automatically using the current user’s role assignments.
    ```
  

## Date/Env
It is 2025 Sept 15 when I'm updating this file.

## Development Workflow

### ⚠️ CRITICAL: One-PR-at-a-Time Rule
**ONLY ONE pull request should be open at any given time.**

Before starting ANY new work:
1. **REQUIRED**: Run `./bin/preflight-check` to verify clean state
2. **REQUIRED**: Check `gh pr list --state open` returns ZERO open PRs
3. **If open PRs exist**: Merge or close them before proceeding
4. **Exception**: Only with explicit "ultrathink" override and documented reasoning

### PR Workflow
- Run preflight check before creating branches
- Complete work fully before creating PR  
- Request review immediately after PR creation
- Merge promptly after approval (same day preferred)
- Delete branch immediately after merge
- Use descriptive branch names: `issue-{number}`, `fix-{description}`, `feature-{description}`

**Why**: Multiple open PRs create merge conflicts, workflow confusion, and make tracking changes difficult.
**Reference**: See [PR_WORKFLOW_STANDARDS.md](./PR_WORKFLOW_STANDARDS.md) for complete details.

# Backstage Pass Platform - AI Assistant Guide (claude.md)

## 📍 Current Documentation Status (Sept 2025)

### 🔴 Start Here:
- **[DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md)** - Central documentation index with reading order
- **[TEAM_SPACE_ARCHITECTURE.md](./TEAM_SPACE_ARCHITECTURE.md)** - Critical architecture decision (READ FIRST)

### Active Docs:
- **[USER_SPECS_PHASE1.md](./USER_SPECS_PHASE1.md)** - Complete Phase 1 specifications
- **[ARCHITECTURE_DECISIONS.md](./ARCHITECTURE_DECISIONS.md)** - Latest technical decisions
- **[HOTWIRE_NATIVE_2025.md](./HOTWIRE_NATIVE_2025.md)** - Mobile implementation (Rails World 2025 patterns)

### Deprecated:
- ~~HOTWIRE_NATIVE.md~~ - Replaced by HOTWIRE_NATIVE_2025.md
- ~~CLARIFICATIONS_NEEDED.md~~ - All resolved, see ARCHITECTURE_DECISIONS.md

## Project Overview

Backstage Pass is a marketplace platform for live streaming and digital experiences. Creators sell "Access Passes" that grant entry to various experiences (live streams, exclusive content, courses, communities). Built with Rails 8, Bullet Train, and Hotwire Native.

### Core Architecture
- **Whop** (marketplace model) + **Interactive streaming** + **Creator monetization**
- Creators have "Spaces" that contain multiple "Experiences" 
- Users purchase "Access Passes" to Spaces or individual Experiences

## Technical Stack

### Required
- Ruby on Rails 8.0+ with Bullet Train framework
- PostgreSQL 15+ / Redis 7+ / Sidekiq
- LiveKit.io for WebRTC / GetStream for chat
- Stripe via Pay gem + Bullet Train
- Hotwire (Turbo + Stimulus) - NO React/Vue for web
- Hotwire Native for iOS/Android

### Never Use
- ❌ React/Vue/Angular for main app
- ❌ Devise directly (use Bullet Train's auth)
- ❌ Manual scaffolding (ALWAYS use super_scaffold)

## 🚨 CRITICAL: Magic Comments (Never Delete!)

```ruby
class Model < ApplicationRecord
  # 🚅 add concerns above.
  
  belongs_to :team
  # 🚅 add belongs_to associations above.
  
  has_many :items
  # 🚅 add has_many associations above.
  
  validates :name, presence: true
  # 🚅 add validations above.
  
  # 🚅 add callbacks above.
  # 🚅 add delegations above.
  # 🚅 add methods above.
end
```

**⚠️ Deleting these 🚅 comments breaks super scaffolding!**

## Super Scaffolding Rules

### Field Types
- `:text_field` - Single line text
- `:trix_editor` - Rich text editor  
- `:buttons` - Button options (configure in locale)
- `:super_select{class_name=Model}` - Association dropdown
- `:boolean` - Checkbox
- `:date_and_time_field` - DateTime picker
- `:number_field` - Number input

### Ownership Chain
- Top-level: `rails g super_scaffold Model Team field:type`
- Nested: `rails g super_scaffold Child Parent,Team field:type`
- Deep: `rails g super_scaffold Deep Parent,GrandParent,Team field:type`

### After Scaffolding
1. Run `rake db:migrate`
2. Configure button options in `config/locales/en/[model].en.yml`
3. Add custom code between magic comments only

## Model Hierarchy

```
User → Membership → Team (account context)
                     ├── Space (creator space)
                     │   ├── Experience (streams, content)
                     │   └── AccessPass (purchasing)
                     └── primary_space (auto-created)
```

## Common Pitfalls

1. ❌ Creating models without super_scaffold
2. ❌ Deleting 🚅 magic comments from models
3. ❌ Forgetting ownership chain (Parent,Team) for nested resources
4. ❌ Skipping team context in queries
5. ❌ Using React/Vue instead of Hotwire
6. ❌ Direct database queries instead of through associations
7. ❌ Custom auth instead of Bullet Train's auth

## Testing with Magic Test

```ruby
# test/system/feature_test.rb
class FeatureTest < ApplicationSystemTestCase
  include MagicTest::Support
  
  test "user action" do
    # Record browser interactions
    MAGIC_TEST=1 rails test test/system/feature_test.rb
    
    # Save recording
    magic_test.save_recording("feature_name")
  end
end
```

## Quick Commands

```bash
# Super scaffold new model
rails g super_scaffold Model Team name:text_field

# Nested model with ownership chain
rails g super_scaffold Experience Space,Team name:text_field

# Add field to existing model
rails g super_scaffold:field Model new_field:text_field

# Add association field
rails g super_scaffold:field Model user_id:super_select{class_name=User}

# Configure button options after scaffolding
# Edit: config/locales/en/models.en.yml
```

## Environment Variables (Production)

```bash
RAILS_MASTER_KEY=xxx
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
BASE_URL=https://backstagepass.app
STRIPE_PUBLISHABLE_KEY=pk_xxx
STRIPE_SECRET_KEY=sk_xxx
LIVEKIT_API_KEY=xxx
LIVEKIT_API_SECRET=xxx
GETSTREAM_API_KEY=xxx
GETSTREAM_API_SECRET=xxx
```