# Backstage Pass - Initial Setup & Testing Guide

## 🚨 CRITICAL: Day 1 Setup (RUN THESE FIRST!)

### Step 1: Initialize Rails with Bullet Train

```bash
# Clone Bullet Train starter repo
git clone git@github.com:bullet-train-co/bullet_train.git backstage-pass
cd backstage-pass

# Install dependencies
bundle install
yarn install

# Setup database
bin/setup
```

### Step 2: EJECT THEME IMMEDIATELY (CRITICAL!)

**This MUST be done before ANY customization so AI can see/modify all views:**

```bash
# EJECT ALL STANDARD VIEWS - This is critical for AI visibility
# Create a new theme called "backstage_pass" with ejected views
rake bullet_train:themes:light:eject[backstage_pass]

# If your shell complains about brackets, escape them:
rake bullet_train:themes:light:eject\[backstage_pass\]

# This will:
# - Copy all views from bullet_train-themes-light gem to app/views/themes/backstage_pass/
# - Configure your application to use the new theme
# - Update config files to reference the new theme

# Verify ejection worked
ls -la app/views/themes/backstage_pass/  # Should see many .html.erb files
ls -la app/views/shared/  # Should have shared components

# You can also eject individual views using bin/resolve
# Example: Eject just the navigation
bin/resolve --interactive shared/navigation
# Then select "Eject this view to my application"

# Commit immediately so we have a baseline
git add .
git commit -m "Ejected Bullet Train theme as backstage_pass for full customization"
```

### Step 3: Install Magic Test for AI-Generated Tests

```bash
# Add to Gemfile development group
cat >> Gemfile << 'EOF'

group :development, :test do
  gem 'magic_test'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
EOF

bundle install

# Configure Magic Test
cat > config/initializers/magic_test.rb << 'RUBY'
if defined?(MagicTest)
  MagicTest.config do |config|
    # Use headless Chrome for CI
    config.use_headless = ENV['HEADLESS'].present?
    
    # Save recordings for AI to learn from
    config.save_recordings = true
    config.recordings_path = Rails.root.join('test/recordings')
    
    # Enable AI-friendly output
    config.verbose = true
    config.generate_complete_test = true
  end
end
RUBY

# Create recordings directory
mkdir -p test/recordings
echo "test/recordings/*.yml" >> .gitignore
```

### Step 4: Setup Custom Theme for Backstage Pass

```bash
# Create our custom theme based on ejected Light theme
rails generate bullet_train:theme "Backstage Pass" --color-scheme="purple"

# This creates:
# - app/views/themes/backstage_pass/
# - app/assets/stylesheets/themes/backstage_pass.scss
# - config/initializers/theme.rb

# Set as default theme
cat > config/initializers/theme.rb << 'RUBY'
Rails.application.config.theme = "backstage_pass"

# Backstage Pass brand colors
Rails.application.config.theme_colors = {
  primary: "#6B46C1",     # Purple
  secondary: "#EC4899",   # Pink
  success: "#10B981",     # Green
  danger: "#EF4444",      # Red
  warning: "#F59E0B",     # Amber
  info: "#3B82F6",        # Blue
  light: "#F3F4F6",       # Gray 100
  dark: "#1F2937"         # Gray 800
}
RUBY
```

### Step 5: Configure Streaming & Mobile Gems

```bash
# Add all required gems
cat >> Gemfile << 'EOF'

# Streaming
gem 'livekit-server-sdk'
gem 'mux-ruby', '~> 3.0'

# Mobile
gem 'turbo-native-initializer'

# Marketplace
gem 'money-rails', '~> 1.15'
gem 'friendly_id', '~> 5.5'

# AI/Processing
gem 'ruby-openai'
gem 'streamio-ffmpeg'

# Monitoring
gem 'bullet', group: :development
gem 'rack-mini-profiler', group: :development
EOF

bundle install
```

## 🧪 Magic Test Integration for AI

### How Magic Test Works with Claude Code

Magic Test allows recording browser interactions and automatically generates system tests. Perfect for AI to create comprehensive UI tests!

### Recording a Test (Manual Process First)

```bash
# 1. Start Rails server
rails server

# 2. In another terminal, start Magic Test recording
MAGIC_TEST=1 rails test test/system/example_test.rb

# 3. Interact with browser (it opens automatically)
# - Click buttons
# - Fill forms  
# - Navigate pages
# Magic Test records everything!

# 4. Press "Stop" in the browser toolbar
# Magic Test generates the complete test code
```

### AI-Generated Test Pattern

Claude Code should create tests like this:

```ruby
# test/system/ai_generated/purchase_flow_test.rb
require "application_system_test_case"

class PurchaseFlowTest < ApplicationSystemTestCase
  include MagicTest::Support # Enable Magic Test
  
  setup do
    # AI should always create test data first
    @creator = create(:user, :with_team)
    @space = create(:space, :published, team: @creator.teams.first)
    @experience = create(:experience, :live_stream, space: @space)
    @buyer = create(:user)
    
    # Start recording if in development
    magic_test.start_recording if ENV['RECORD_TEST']
  end
  
  test "user can purchase access pass for space" do
    # Sign in
    visit new_user_session_path
    magic_test.record_action do
      fill_in "Email", with: @buyer.email
      fill_in "Password", with: "password"
      click_button "Sign In"
    end
    
    # Navigate to space
    visit space_path(@space)
    assert_selector "h1", text: @space.name
    
    # Purchase flow
    magic_test.record_action do
      click_button "Get Access Pass"
      
      # Stripe checkout (mocked in test)
      within_frame find("iframe[name='stripe_checkout']") do
        fill_in "cardNumber", with: "4242424242424242"
        fill_in "cardExpiry", with: "12/34"
        fill_in "cardCvc", with: "123"
        click_button "Pay"
      end
    end
    
    # Verify success
    assert_selector ".alert-success", text: "Access granted!"
    assert @buyer.access_passes.active.exists?
    
    # Save recording for future reference
    magic_test.save_recording("purchase_flow")
  end
end
```

### Magic Test Commands for Claude Code

```ruby
# lib/tasks/magic_test.rake
namespace :magic_test do
  desc "Generate test from user interaction"
  task :generate, [:test_name] => :environment do |t, args|
    test_name = args[:test_name] || "generated_test"
    
    puts "Starting Magic Test recording..."
    puts "1. Browser will open"
    puts "2. Perform the actions you want to test"
    puts "3. Click 'Stop Recording' in the toolbar"
    puts "4. Test will be generated at: test/system/ai_generated/#{test_name}_test.rb"
    
    ENV['MAGIC_TEST'] = '1'
    ENV['MAGIC_TEST_OUTPUT'] = "test/system/ai_generated/#{test_name}_test.rb"
    
    system("rails test test/system/magic_test_recorder.rb")
  end
  
  desc "Replay and verify all AI-generated tests"
  task :verify => :environment do
    Dir.glob("test/system/ai_generated/*_test.rb").each do |test_file|
      puts "Running: #{test_file}"
      system("rails test #{test_file}")
    end
  end
  
  desc "Generate test from recorded actions"
  task :from_recording, [:recording_file] => :environment do |t, args|
    recording = YAML.load_file("test/recordings/#{args[:recording_file]}.yml")
    
    test_code = MagicTest::TestGenerator.new(recording).generate
    
    output_file = "test/system/ai_generated/#{args[:recording_file]}_test.rb"
    File.write(output_file, test_code)
    
    puts "Generated test: #{output_file}"
  end
end
```

### AI Instructions for Creating Tests

When Claude Code needs to create a UI test:

```ruby
# 1. First, create the test skeleton
rails generate system_test ai_generated/feature_name

# 2. Add Magic Test support
class FeatureNameTest < ApplicationSystemTestCase
  include MagicTest::Support
  
  # 3. Create comprehensive setup data
  setup do
    # Create all necessary records
    # Mock external services
    # Set feature flags if needed
  end
  
  # 4. Write interaction tests
  test "complete user journey" do
    # Use magic_test.record_action for complex interactions
    magic_test.record_action do
      # User actions here
    end
    
    # Always assert the outcome
    assert_selector "css_selector"
    assert_equal expected, actual
    assert model.attribute_changed?
  end
end

# 5. Run the test
rails test test/system/ai_generated/feature_name_test.rb

# 6. If it passes, save as recording
SAVE_RECORDING=1 rails test test/system/ai_generated/feature_name_test.rb
```

## 🎨 Theme Customization After Ejection

Now that views are ejected, Claude Code can modify them directly:

### Example: Customizing the Navigation

```erb
<!-- app/views/shared/_navigation.html.erb -->
<!-- AI CAN NOW SEE AND MODIFY THIS DIRECTLY! -->

<nav class="bg-purple-600 text-white">
  <div class="container mx-auto px-4">
    <div class="flex justify-between items-center h-16">
      <!-- Logo -->
      <div class="flex items-center">
        <%= link_to root_path, class: "flex items-center space-x-2" do %>
          <svg class="w-8 h-8"><!-- Backstage Pass Logo --></svg>
          <span class="font-bold text-xl">Backstage Pass</span>
        <% end %>
      </div>
      
      <!-- Navigation Items -->
      <div class="hidden md:flex items-center space-x-8">
        <%= link_to "Spaces", spaces_path, 
            class: "hover:text-purple-200 transition" %>
        <%= link_to "Live Now", live_streams_path, 
            class: "flex items-center space-x-1 hover:text-purple-200" %>
          <span class="relative flex h-2 w-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
            <span class="relative inline-flex rounded-full h-2 w-2 bg-red-500"></span>
          </span>
          <span>Live</span>
        <% end %>
      </div>
      
      <!-- User Menu -->
      <div class="flex items-center space-x-4">
        <% if current_user %>
          <%= render "shared/user_menu" %>
        <% else %>
          <%= link_to "Sign In", new_user_session_path, 
              class: "btn btn-ghost" %>
          <%= link_to "Get Started", new_user_registration_path, 
              class: "btn btn-primary" %>
        <% end %>
      </div>
    </div>
  </div>
</nav>
```

### Customizing Bullet Train Components

```erb
<!-- app/views/shared/forms/_field.html.erb -->
<!-- Now visible and editable after ejection! -->

<div class="form-group <%= 'has-error' if form.object.errors[method].any? %>">
  <% if local_assigns[:label] != false %>
    <%= form.label method, class: "block text-sm font-medium text-gray-700 mb-1" %>
  <% end %>
  
  <div class="relative">
    <!-- Add custom Backstage Pass styling -->
    <%= form.send(helper, method, options.merge(
      class: "form-input block w-full rounded-md border-gray-300 
              focus:border-purple-500 focus:ring-purple-500"
    )) %>
    
    <% if form.object.errors[method].any? %>
      <p class="mt-1 text-sm text-red-600">
        <%= form.object.errors[method].first %>
      </p>
    <% end %>
  </div>
</div>
```

## 📁 Project Structure After Setup

```
backstage-pass/
├── .claude/
│   ├── config.yml           # Claude Code configuration
│   ├── pre-flight.sh        # Pre-execution checks
│   ├── project-management.md # This guide
│   └── verify.sh            # Verification scripts
├── app/
│   ├── views/
│   │   ├── shared/          # ✅ Ejected and visible!
│   │   ├── themes/
│   │   │   └── backstage_pass/ # Our custom theme
│   │   └── devise/          # ✅ Ejected auth views
│   └── assets/
│       └── stylesheets/
│           └── themes/
│               └── backstage_pass.scss
├── test/
│   ├── system/
│   │   └── ai_generated/    # AI-created Magic Tests
│   └── recordings/          # Magic Test recordings
├── claude.md               # Main AI instructions
├── TASKS.md               # Task tracking
├── SETUP_GUIDE.md         # This file
└── HOTWIRE_NATIVE.md      # Mobile guide
```

## 🔍 Verification After Setup

Run this to ensure everything is properly configured:

```bash
#!/bin/bash
# .claude/verify-setup.sh

echo "🔍 Verifying Backstage Pass Setup..."

# 1. Check theme ejection
if [ ! -f "app/views/shared/_navigation.html.erb" ]; then
  echo "❌ Theme not ejected! Run: rails generate bullet_train:themes:light:eject"
  exit 1
fi

# 2. Check Magic Test
if ! grep -q "magic_test" Gemfile.lock; then
  echo "❌ Magic Test not installed!"
  exit 1
fi

# 3. Check custom theme
if [ ! -d "app/views/themes/backstage_pass" ]; then
  echo "⚠️  Custom theme not created yet"
fi

# 4. Check streaming gems
for gem in livekit-server-sdk mux-ruby turbo-native-initializer; do
  if ! grep -q "$gem" Gemfile.lock; then
    echo "⚠️  Missing gem: $gem"
  fi
done

# 5. Run initial tests
echo "Running initial test suite..."
rails test

echo "✅ Setup verification complete!"
```

## 🚀 Quick Start After Setup

```bash
# Every new Claude Code session should:

# 1. Verify setup
bash .claude/verify-setup.sh

# 2. Check current task
rake claude:status

# 3. Run any pending migrations
rails db:migrate

# 4. Start the server with Magic Test enabled
MAGIC_TEST=1 rails server

# 5. In another terminal, start working on current task
rake claude:next
```

## 🎯 Why This Setup Order Matters

1. **Theme Ejection First**: Without this, AI cannot see or modify views - they're hidden in the gem
2. **Magic Test Early**: Allows AI to generate tests as features are built
3. **Custom Theme**: Establishes brand identity before building features
4. **Verification Scripts**: Ensures nothing is missed before development begins

This setup ensures Claude Code has full visibility and control over the application from day one!