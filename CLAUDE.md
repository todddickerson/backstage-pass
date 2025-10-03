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
It is 2025 Oct 3 when I'm updating this file.

## 🐛 Common Issues & Solutions (Learned Oct 2025)

### CSS Not Loading / Black Circles on Pages

**Symptoms:**
- Pages show giant black circles or unstyled content
- SVG icons render at 1000px+ instead of proper size
- Tailwind classes don't apply
- Browser shows "MIME type 'text/plain'" errors for CSS

**Root Causes & Fixes:**

#### 1. Missing Layout File
**Problem:** Controller declares `layout "public"` but file doesn't exist
**Fix:** Create `app/views/layouts/public.html.erb`:
```erb
<!DOCTYPE html>
<html lang="en">
<head>
  <%= render 'layouts/head' %>
  <%= stylesheet_link_tag "application.backstage_pass", "data-turbo-track": "reload" %>
  <%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>
</head>
<body class="min-h-screen bg-gray-50">
  <%= yield %>
</body>
</html>
```

#### 2. Propshaft + Theme CSS Naming Mismatch
**Problem:** Bullet Train builds `application.backstage_pass.css` but layouts reference `application.css`
**Why:** Propshaft serves from `app/assets/builds/` with content-based hashing
**Solution:** Build pipeline must copy files (symlinks don't work):

**Update `package.json`:**
```json
"build:css": "bin/link; yarn backstage_pass:build:css; yarn backstage_pass:build:mailer:css; cp app/assets/builds/application.backstage_pass.css app/assets/builds/application.css; cp app/assets/builds/application.backstage_pass.css app/assets/builds/application.light.css"
```

**Create `bin/watch-css-copy`:**
```bash
#!/usr/bin/env bash
SOURCE="app/assets/builds/application.backstage_pass.css"
echo "👀 Watching $SOURCE for changes..."

if [ -f "$SOURCE" ]; then
  cp "$SOURCE" app/assets/builds/application.css
  cp "$SOURCE" app/assets/builds/application.light.css
  echo "✅ Initial CSS copied"
fi

# Watch with fswatch or poll fallback
if command -v fswatch &> /dev/null; then
  fswatch -o "$SOURCE" | while read; do
    cp "$SOURCE" app/assets/builds/application.css
    cp "$SOURCE" app/assets/builds/application.light.css
    echo "✅ CSS updated"
  done
else
  while true; do
    sleep 2
    [ -f "$SOURCE" ] && cp "$SOURCE" app/assets/builds/application.css && cp "$SOURCE" app/assets/builds/application.light.css
  done
fi
```

**Update `Procfile.dev`:**
```
css-copy: bin/watch-css-copy
```

**Why Symlinks Fail:**
- Propshaft calculates content hashes for cache busting
- Symlinks confuse hash calculation
- Files get served with MIME type 'text/plain' instead of 'text/css'
- Browser refuses to apply stylesheet

#### 3. Propshaft Serving Empty Cached CSS
**Problem:** After rebuild, Propshaft still serves old empty/stale CSS files
**Symptoms:** File exists with correct content but `curl /assets/application-{hash}.css` returns 0 lines
**Fix:**
```bash
# Clear all caches
rm -rf tmp/cache tmp/pids

# Kill servers completely
pkill -9 -f "puma|overmind"
rm -f .overmind.sock

# Rebuild CSS fresh
yarn build:css

# Restart server
bin/dev
```

**Prevention:** Always restart server after CSS changes to force Propshaft to recalculate hashes.

---

### Authorization / Permissions Errors

**Symptoms:**
- "You are not authorized to access this page"
- "Add New Experience" button triggers access denied
- Forms submit but redirect with authorization error

**Root Cause:** `config/models/roles.yml` only grants `read` permission by default

**Solution:**

#### 1. Update roles.yml for Creator Permissions
```yaml
default:  # Applies to ALL team members
  models:
    Experience:
      - read
      - create    # ADD THIS
      - update    # ADD THIS
    Stream:
      - read
      - create    # ADD THIS
      - update    # ADD THIS
    Space:
      - read
      - update    # ADD THIS
```

#### 2. CRITICAL: Restart Server After roles.yml Changes
**Why:** Rails caches roles at boot time. Changes to `roles.yml` don't take effect until restart.

```bash
pkill -9 -f "puma|overmind"
rm -f .overmind.sock tmp/pids/server.pid
bin/dev
```

#### 3. Understanding Permission Levels
- `read` - Can view resources
- `create` - Can create new resources
- `update` - Can edit existing resources
- `destroy` - Can delete resources (typically admin-only)
- `manage` - Full CRUD (shorthand for all above)

**Best Practice:**
- `default` role: Grant create/update for user-generated content
- `admin` role: Use `manage` for full control including destroy
- Keep `destroy` limited to admins for safety

---

### Debugging Permissions

```ruby
# In Rails console
user = User.find_by(email: "user@example.com")
team = user.teams.first
membership = user.memberships.find_by(team: team)

# Check roles
puts membership.roles.map(&:key)  # => ["default", "admin"]

# Check specific model permissions
puts membership.roles.first.models["Experience"]  # => ["read", "create", "update"]
```

**Common Mistakes:**
1. Forgetting to restart server after `roles.yml` changes
2. Using only `read` when users need to create content
3. Not understanding `default` role applies to EVERYONE
4. Bypassing `account_load_and_authorize_resource` with manual checks

## Development Workflow

### 🎯 GitHub Task Management (CRITICAL)

**ALWAYS at conversation/session start:**
```bash
bin/gh-sync                      # Sync GitHub issues to local
cat AI_CURRENT_TASKS.md          # Review prioritized task list
bin/gh-project-status            # Check project board
```

**Task workflow:**
```bash
bin/gh-start <issue-number>      # Start working on issue
# ... implement feature ...
bin/gh-complete <issue-number> "message"  # Complete with PR
```

**Critical Rules:**
1. **ALWAYS run `bin/gh-sync` at conversation start**
2. **NEVER create models without checking existing issues**
3. **ALWAYS work on priority/critical first**
4. **NEVER leave issues in ai/working state**
5. **ALWAYS check AI_CURRENT_TASKS.md for work**

See [GITHUB_TASK_MANAGEMENT.md](./GITHUB_TASK_MANAGEMENT.md) for complete system.

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

## 🔧 Bullet Train File Ejection & Customization

### Decision Matrix: Eject vs Alternatives

**✅ EJECT WHEN:**
- Substantial onboarding flow changes needed
- Authentication controller customization required
- Business logic conflicts with framework defaults
- Need explicit control over security-critical code

**❌ AVOID EJECTION:**
- Simple view/styling changes (use theme system)
- Minor validation tweaks (use extension points)
- Quick fixes (explore `bin/resolve` first)
- Timezone/locale issues (often config problems)

### File Ejection Process
```bash
# 1. Investigate first
bin/resolve Account::Onboarding::UserDetailsController --open

# 2. Understand the code, then eject if needed
bin/resolve Account::Onboarding::UserDetailsController --eject

# 3. Document why ejected in commit message
git commit -m "Eject user details controller for custom timezone validation"
```

### 🚨 Onboarding Customization Patterns

**Prefer Extension Points:**
```ruby
# In application_controller.rb
def ensure_onboarding_is_complete
  super # Call framework method first
  
  # Add custom checks
  if current_user.missing_custom_field?
    redirect_to custom_onboarding_step_path
  end
end
```

**Common Ejection Targets:**
- `app/controllers/account/onboarding/user_details_controller.rb`
- `app/views/account/onboarding/user_details/`
- `app/controllers/account/users/registrations_controller.rb`

### Timezone Validation Bug Patterns
- **Issue**: JS timezone detection vs Rails timezone names mismatch
- **Solution**: Convert `Intl.DateTimeFormat().resolvedOptions().timeZone` to Rails format
- **Testing**: Verify both auto-detection and manual selection paths
- **Fallback**: Always provide manual timezone selector

### 🔒 Security Implications
- **Ejected auth files = security maintenance burden**
- **Update framework regularly** (security patches in ejected files won't auto-apply)
- **Document all security customizations**
- **Test 2FA/encryption changes thoroughly**

### Maintenance Strategy
- **Document business rationale** for each ejection
- **Regular ejection review** (quarterly) - can we remove?
- **Framework upgrade testing** - ejected files need manual reconciliation
- **Version lock carefully** - understand upgrade implications

### 🧪 Testing Ejected Components
```ruby
# Test both framework integration AND custom logic
test "custom onboarding integrates with framework flow" do
  # Test framework expectations
  assert_redirected_to account_onboarding_user_details_path
  
  # Test custom behavior
  assert @user.custom_field_completed?
end
```

### Red Flags 🚩
- **Monkey patching framework code** (high risk, prefer ejection)
- **Ejecting files without understanding them**
- **Not documenting customization rationale**
- **Skipping security review for auth changes**