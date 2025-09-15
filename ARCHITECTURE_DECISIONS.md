# Backstage Pass - Architecture Decisions & Research Findings

## Executive Summary

Based on your clarifications and deep research, here are the key architectural decisions and immediate implementation priorities:

### 🔴 Critical Architecture Changes Needed

1. **AccessPass Model Redesign** - Must support flexible Experience selection, not simple polymorphic
2. **Creator Profile Model** - New model needed outside Team context
3. **Route Structure** - Complex public/member/admin routes requiring custom implementation
4. **Chat Platform Decision** - GetStream.io recommended over LiveKit data channels
5. **Mobile Video** - Native players required for LiveKit/WebRTC streaming

## 1. AccessPass & Pricing Architecture

### Decision Required: Model Structure

Your requirements indicate AccessPasses need more complex structure than originally planned:

```ruby
# ORIGINAL (Too Simple)
class AccessPass < ApplicationRecord
  belongs_to :purchasable, polymorphic: true # Space or Experience
end

# REQUIRED (Based on Your Specs)
class AccessPass < ApplicationRecord
  belongs_to :space
  has_many :access_pass_experiences
  has_many :experiences, through: :access_pass_experiences
  
  # Pricing fields
  monetize :initial_fee_cents
  monetize :recurring_price_cents
  
  # Pricing model
  enum pricing_type: { free: 0, one_time: 1, recurring: 2 }
  enum billing_period: { monthly: 0, yearly: 1, lifetime: 2 }
  
  # Waitlist functionality
  boolean :waitlist_enabled
  text :waitlist_questions # JSON
  
  # Access control
  integer :stock_remaining
  integer :trial_days
  datetime :auto_expire_at
  
  # Checkout customization
  text :redirect_url
  text :cancellation_discount # JSON
  boolean :split_payments_enabled
  integer :max_split_payments
end

class AccessPassExperience < ApplicationRecord
  belongs_to :access_pass
  belongs_to :experience
  boolean :included, default: true
end
```

### Implementation Notes:
- Need join table for Experience selection (not polymorphic)
- Complex pricing requires multiple monetized fields
- Waitlist feature needs separate workflow/controller
- Stock tracking needs Redis counters for race conditions

## 2. Creator Profile & Team Structure

### New Model Required

```ruby
# app/models/creator_profile.rb
class CreatorProfile < ApplicationRecord
  belongs_to :user
  
  # Slug for @username routes
  extend FriendlyId
  friendly_id :username, use: :slugged
  
  # Profile info
  string :username, unique: true
  text :bio
  string :avatar_url
  string :cover_image_url
  
  # Associations
  has_many :space_creators
  has_many :spaces, through: :space_creators
  
  # Analytics (cached)
  integer :total_followers
  integer :total_revenue_cents
end

# Junction table for Space ownership
class SpaceCreator < ApplicationRecord
  belongs_to :space
  belongs_to :creator_profile
  enum role: { owner: 0, collaborator: 1 }
end
```

### Route Structure Impact

**Note:** Using `/account/` namespace for member experiences instead of creating a new `/m/` namespace to reduce complexity and maintain consistency with Bullet Train's architecture. This keeps all authenticated user actions within the existing account context.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Creator profiles
  get '@:username', to: 'public/creator_profiles#show'
  
  # Public sales pages
  scope module: 'public' do
    get ':space_slug', to: 'spaces#show'
    get ':space_slug/:access_pass_slug', to: 'access_passes#show'
    post ':space_slug/:access_pass_slug/purchase', to: 'purchases#create'
  end
  
  # Account management (Bullet Train) - includes member experiences
  namespace :account do
    # Standard Bullet Train routes
    
    # Member experience routes (post-purchase)
    # Using /account/ namespace to maintain Bullet Train consistency
    resources :purchased_spaces, only: [:index, :show] do
      resources :experiences, only: [:show] do
        member do
          get :stream
          get :chat
        end
      end
    end
  end
end
```

## 3. Chat Platform Decision: GetStream.io

### Research Findings

Based on comprehensive research, **GetStream.io is strongly recommended** over LiveKit data channels:

**GetStream.io Advantages:**
- Complete chat SDK with reactions, threads, file sharing built-in
- Message persistence and history included
- Moderation tools and AI spam detection included
- Rails SDK available with simple integration
- Scales to 1000+ concurrent users automatically
- Cost: ~$500-2000/month for typical usage

**LiveKit Data Channels Disadvantages:**
- No message persistence (must build custom)
- No moderation tools (must integrate third-party)
- Limited to 15KB reliable messages
- Requires extensive custom development (3-6 months)
- Complex state management across clients

### Implementation Approach

```ruby
# Gemfile
gem 'stream-chat-ruby'

# app/services/chat_service.rb
class ChatService
  def self.client
    @client ||= StreamChat::Client.new(
      api_key: ENV['GETSTREAM_API_KEY'],
      api_secret: ENV['GETSTREAM_API_SECRET']
    )
  end
  
  def self.create_channel_for_experience(experience)
    channel = client.channel('livestream', experience.slug,
      name: experience.name,
      created_by_id: experience.space.creator_profile.user_id
    )
    channel.create(experience.space.creator_profile.user_id)
  end
  
  def self.generate_user_token(user)
    client.create_token(user.id.to_s)
  end
end
```

## 4. Bullet Train Locale Configuration

### Research Finding: Button Options Format

Based on Bullet Train documentation research, the correct locale format for button options:

```yaml
# config/locales/en/spaces.en.yml
en:
  spaces:
    fields:
      status:
        _: &status Status
        label: *status
        heading: *status
        choices:
          draft: Draft
          published: Published
          archived: Archived
      
      # For options with colors/icons (custom implementation needed)
      visibility:
        _: &visibility Visibility
        label: *visibility
        choices:
          public:
            label: Public
            description: "Anyone can view"
            # Icons/colors must be handled in view partial
          private:
            label: Private
            description: "Invite only"
```

**Important:** Bullet Train doesn't natively support icons/colors in locale files. You'll need custom partials:

```erb
<!-- app/views/themes/backstage_pass/fields/_status_buttons.html.erb -->
<% choices = t("spaces.fields.#{method}.choices").to_h %>
<% choices.each do |value, label| %>
  <%= form.radio_button method, value, 
      class: "btn btn-#{status_color(value)}" %>
  <i class="ti ti-<%= status_icon(value) %>"></i>
  <%= label %>
<% end %>
```

## 5. Mobile Video Strategy

### Decision: Native Players Required

Research indicates **native video players are required** for LiveKit WebRTC:

**Implementation Strategy:**
1. Use native LiveKit SDKs for iOS/Android
2. Create JavaScript bridge for Hotwire Native
3. Web player fallback for non-critical features

```javascript
// app/javascript/bridges/video_player.js
export class VideoPlayerBridge {
  static connect(element) {
    const platform = element.dataset.platform;
    const streamUrl = element.dataset.streamUrl;
    
    if (platform === 'ios' || platform === 'android') {
      // Send to native player via bridge
      window.HotwireNative.playVideo({
        url: streamUrl,
        type: 'livekit',
        token: element.dataset.token
      });
    } else {
      // Use web player
      new LivekitWebPlayer(element);
    }
  }
}
```

## 6. Deployment Strategy: Kamal 2

### Rails 8 with Kamal 2 Configuration

```yaml
# config/deploy.yml
service: backstage-pass
image: backstagepass/app

servers:
  web:
    - 192.168.0.1
  worker:
    - 192.168.0.2

registry:
  username: <%= ENV['DOCKER_REGISTRY_USER'] %>
  password: <%= ENV['DOCKER_REGISTRY_PASS'] %>

env:
  clear:
    RAILS_ENV: production
  secret:
    - RAILS_MASTER_KEY
    - LIVEKIT_API_KEY
    - GETSTREAM_API_KEY

accessories:
  postgres:
    image: postgres:15
    host: 192.168.0.3
    env:
      POSTGRES_PASSWORD: <%= ENV['POSTGRES_PASSWORD'] %>
    volumes:
      - /data/postgres:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    host: 192.168.0.4
    volumes:
      - /data/redis:/data
```

## 7. Near-Term Architecture Modifications

### Phase 1: Core Models (Week 1-2)
1. **Create CreatorProfile model** - Not in original plan
2. **Redesign AccessPass** - More complex than polymorphic
3. **Add AccessPassExperience join table** - New requirement
4. **Implement waitlist workflow** - Complex new feature

### Phase 2: Public Pages (Week 2-3)
1. **Public::SpacesController** - Sales pages
2. **Public::AccessPassesController** - Checkout flow
3. **Passwordless auth** - 6-digit code system
4. **Stripe Elements integration** - Not Stripe Checkout
5. **Manual waitlist approval** - Simple admin UI

### Phase 3: Chat Integration (Week 3-4)
1. **GetStream.io setup** - Replace LiveKit data channels plan
2. **Channel creation per Experience**
3. **Moderation dashboard**
4. **Rich messaging features**

### Phase 4: Streaming (Week 4-5)
1. **LiveKit for video only** - Not chat
2. **Hybrid Mux distribution** - Based on viewer count
3. **Native mobile players** - Not web players
4. **Recording to R2** - Not S3

## 8. Database Schema Changes

### Required Indexes

```ruby
class AddCriticalIndexes < ActiveRecord::Migration[8.0]
  def change
    # AccessPass lookups
    add_index :access_passes, [:space_id, :status]
    add_index :access_pass_experiences, [:access_pass_id, :experience_id], 
              name: 'index_pass_experiences'
    
    # Creator profile lookups
    add_index :creator_profiles, :username, unique: true
    add_index :creator_profiles, :user_id
    
    # Space slug lookups
    add_index :spaces, :slug, unique: true
    
    # Purchase queries
    add_index :purchases, [:user_id, :access_pass_id]
    add_index :purchases, [:access_pass_id, :status]
  end
end
```

## 9. Background Jobs Architecture

### Sidekiq Job Structure

```ruby
# app/jobs/stream_start_job.rb
class StreamStartJob < ApplicationJob
  def perform(stream_id)
    stream = Stream.find(stream_id)
    
    # Create LiveKit room
    room = LiveKitService.create_room(stream)
    
    # Create GetStream channel
    ChatService.create_channel_for_experience(stream.experience)
    
    # Notify subscribers
    stream.experience.subscribers.find_each do |user|
      StreamStartNotification.new(stream, user).deliver_later
    end
    
    # Start recording if enabled
    RecordingStartJob.perform_later(stream_id) if stream.record?
  end
end

# app/jobs/access_pass_cleanup_job.rb  
class AccessPassCleanupJob < ApplicationJob
  def perform
    AccessPass.expired.find_each do |pass|
      pass.expire!
      AccessPassExpiredNotification.new(pass).deliver_later
    end
  end
end
```

## 10. Testing Strategy

### Magic Test for Critical Paths Only

```ruby
# test/system/purchase_flow_test.rb
class PurchaseFlowTest < ApplicationSystemTestCase
  include MagicTest::Support
  
  test "user purchases access pass" do
    space = create(:space)
    access_pass = create(:access_pass, space: space)
    
    visit public_space_path(space.slug)
    
    magic_test.record_action do
      click_button "Get Access"
      
      # Passwordless auth
      fill_in "Email", with: "buyer@example.com"
      click_button "Send Code"
      
      # Enter code (mocked in test)
      fill_in "Code", with: "123456"
      click_button "Verify"
      
      # Stripe Elements (mocked)
      within_frame("stripe-card-element") do
        fill_in_stripe_card
      end
      
      click_button "Purchase"
    end
    
    assert_current_path account_purchased_space_path(space)
  end
end
```

## Deferred Features (Phase 2+)

Based on clarifications, these features are deferred to later phases:

1. **Waitlist Approval Workflow**
   - **Decision:** Manual approval only for MVP
   - Simple admin interface to approve/reject
   - Email notifications can be added later
   - Bulk approval features deferred
   
   ```ruby
   # Simple implementation for MVP
   class Account::WaitlistEntriesController < Account::ApplicationController
     def index
       @entries = current_team.waitlist_entries.pending
     end
     
     def approve
       @entry = current_team.waitlist_entries.find(params[:id])
       @entry.approve!
       # Creates AccessPass and sends welcome email
       redirect_back(fallback_location: account_waitlist_entries_path)
     end
     
     def reject
       @entry = current_team.waitlist_entries.find(params[:id])
       @entry.reject!
       redirect_back(fallback_location: account_waitlist_entries_path)
     end
   end
   ```

2. **Split Payment Implementation**
   - **Decision:** Deferred to Phase 2
   - Focus on single payment flow initially
   - Can add Stripe Payment Plans later

3. **Search & Discovery**
   - **Decision:** Deferred, will use vector database
   - Basic filtering/categories for MVP
   - Vector DB (pgvector or Pinecone) for semantic search later
   - AI-powered recommendations in Phase 2

4. **Creator Payouts**
   - **Decision:** Deferred to Phase 2
   - Platform-owned model initially
   - Stripe Connect integration later
   - Tax handling complexity pushed out

## Recommended Next Steps

1. **Update CLAUDE.md** with these architectural decisions
2. **Create migration plan** for AccessPass model changes
3. **Set up GetStream.io account** for development
4. **Design waitlist approval UI** mockups
5. **Create CreatorProfile model** first (blocks other work)

## Cost Implications

### Monthly Infrastructure Costs (Estimated)
- GetStream.io Chat: $500-2000
- LiveKit Cloud: $500-3000 (or self-host)
- Cloudflare R2: $50-200
- Kamal hosting (4 servers): $200-500
- Monitoring (Sentry/PostHog): $100-200
- **Total: $1,350-5,900/month**

### Development Time Changes
- **Added 2-3 weeks** for AccessPass complexity
- **Saved 2-3 months** using GetStream.io vs LiveKit chat
- **Added 1 week** for waitlist features
- **Net: Similar timeline, better features**

---

This document represents the current architectural state based on research and your clarifications. Update as decisions are finalized.