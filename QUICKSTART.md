# 🚀 Claude Code Quick Start Reference

## ⚡ Start Every Session With This

```bash
# 1. CHECK SETUP (30 seconds)
ls app/views/shared/*.html.erb  # ❌ If empty = THEME NOT EJECTED!
grep magic_test Gemfile.lock    # ❌ If missing = NO UI TESTING!

# 2. RUN PRE-FLIGHT (10 seconds)  
bash .claude/pre-flight.sh      # Catches all issues

# 3. CHECK STATUS (5 seconds)
rake claude:status               # Shows current task & progress

# 4. START WORK
rake claude:next                 # Move to next task
```

## 🔴 CRITICAL: If Theme Not Ejected

**YOU CANNOT WORK ON VIEWS UNTIL THIS IS DONE:**

```bash
rails generate bullet_train:themes:light:eject
git add . && git commit -m "Ejected theme - views now visible"
```

## 📋 Essential Files to Check

| File | Purpose | Check Command |
|------|---------|---------------|
| `TASKS.md` | Current tasks & bugs | `head -30 TASKS.md` |
| `claude.md` | Core instructions | `grep "NEVER\|ALWAYS" claude.md` |
| `.claude/project-management.md` | Workflows & verification | `cat .claude/project-management.md` |
| `SETUP_GUIDE.md` | Initial setup steps | `grep "CRITICAL" SETUP_GUIDE.md` |

## 🛠️ Most Common Commands

### Creating Features (ALWAYS use super_scaffold)
```bash
# ✅ CORRECT - Always use this
rails generate super_scaffold ModelName ParentModel field:field_type --sidebar="icon"

# ❌ NEVER use regular generators
rails generate model ModelName  # FORBIDDEN!
```

### Creating Tests (ALWAYS use Magic Test)
```bash
# Generate test skeleton
rails generate system_test ai_generated/feature_name

# Run with recording
MAGIC_TEST=1 rails test test/system/ai_generated/feature_name_test.rb

# Save recording
SAVE_RECORDING=1 rails test test/system/ai_generated/feature_name_test.rb

# Verify all tests
rake magic_test:verify
```

### Working with Views (ONLY after ejection)
```erb
<!-- app/views/shared/_navigation.html.erb -->
<!-- ✅ Can edit directly after ejection -->

<!-- ❌ If file doesn't exist = THEME NOT EJECTED -->
```

## 🚫 Never Do These

1. **❌ Create models without super_scaffold**
   ```bash
   rails generate model Space  # WRONG!
   ```

2. **❌ Skip team context**
   ```ruby
   Space.all  # WRONG!
   current_team.spaces  # CORRECT!
   ```

3. **❌ Use React/Vue**
   ```javascript
   import React from 'react'  // FORBIDDEN!
   ```

4. **❌ Skip Access Pass checks**
   ```ruby
   def show
     @stream = Stream.find(params[:id])  # WRONG - no auth!
   end
   ```

5. **❌ Modify views before ejecting theme**
   ```bash
   # If app/views/shared/ is empty, you CANNOT work on views!
   ```

## ✅ Always Do These

1. **✅ Use super_scaffold for everything**
2. **✅ Include Magic Test in system tests**
3. **✅ Check theme ejection before view work**
4. **✅ Maintain team context**
5. **✅ Verify Access Pass for marketplace features**
6. **✅ Use Hotwire (Turbo/Stimulus) for interactivity**
7. **✅ Follow Bullet Train patterns**
8. **✅ Create tests as you build features**

## 🏗️ Project Structure

```
backstage-pass/
├── 📁 .claude/                 # Project management
│   ├── pre-flight.sh          # Run first every session
│   ├── project-management.md   # Detailed workflows
│   └── verify-setup.sh        # Check setup completeness
├── 📁 app/
│   ├── views/
│   │   ├── shared/            # ⚠️ MUST have files (ejected)
│   │   └── themes/
│   │       └── backstage_pass/ # ⚠️ MUST exist (ejected theme)
│   └── models/                # Use concerns/bases
├── 📁 test/
│   ├── system/
│   │   └── ai_generated/      # Your Magic Tests here
│   └── recordings/            # Saved interactions
├── 📄 TASKS.md                # Current work items
├── 📄 claude.md               # Core AI instructions
├── 📄 CLAUDE_COMMANDS.md      # Complete command reference
├── 📄 SETUP_GUIDE.md          # Setup requirements
├── 📄 HOTWIRE_NATIVE.md       # Mobile guide
└── 📄 QUICKSTART.md           # This file

```

## 🎯 Current Focus

```bash
# See what you should be working on
rake claude:status

# Typical task progression:
1. Theme ejection & setup ← IF NOT DONE
2. Core models (Space, Experience, AccessPass)
3. Purchase flow with Stripe
4. LiveKit streaming integration
5. Mobile app with Hotwire Native
```

## 🔧 Debugging

### If something isn't working:

```bash
# 1. Check pre-flight
bash .claude/pre-flight.sh

# 2. Verify setup
bash .claude/verify-setup.sh

# 3. Check for missing migrations
rails db:migrate:status

# 4. Run tests
rails test
rake magic_test:verify

# 5. Check logs
tail -f log/development.log
```

## 💡 Pro Tips

1. **Commit after theme ejection** - It's a lot of files
2. **Create Magic Tests as you build** - Don't wait
3. **Use `@current` marker in TASKS.md** - Track progress
4. **Run pre-flight often** - Catches issues early
5. **Check team context** - Every query should scope to team

## 🚦 Ready Check

Before starting ANY feature work:

- [ ] Theme ejected? (`ls app/views/shared/`)
- [ ] Magic Test installed? (`grep magic_test Gemfile.lock`)
- [ ] Pre-flight passing? (`bash .claude/pre-flight.sh`)
- [ ] Current task clear? (`rake claude:status`)
- [ ] Tests passing? (`rails test`)

**If all checked ✅ → Start building!**
**If any ❌ → Fix setup first!**

---

*Remember: This is a marketplace platform where creators sell access to experiences. Every feature should support this model while following Bullet Train conventions.*