# Phase 1 REVISED - Simplified & Framework-Compliant

## 🔴 Corrections to My Analysis

### 1. Authentication - Passwordless IS Possible
- **Original Plan**: Passwordless with 6-digit codes ✓
- **Implementation**: Custom 6-digit OTP system using Bullet Train patterns
- **Note**: devise-passwordless uses magic links, not codes - we'll build custom

### 2. Payment Processing  
- **OLD**: Stripe Elements (custom forms)
- **NEW**: Stripe Checkout (hosted)
- **Why**: 2-3 days vs 2 weeks development time

### 3. Chat System
- **OLD**: GetStream.io ($500-2000/month extra)
- **NEW**: LiveKit data channels (included with video)
- **Why**: Reduce costs and complexity for MVP

### 4. Mobile Apps
- **OLD**: Week 5-5.5 (unrealistic)
- **NEW**: Phase 2 (3 weeks minimum)
- **Why**: Native video players require significant development

### 5. AccessPass Model
- **Keep Original**: Complex with Experience selection via join table
- **Implementation**: Use super_scaffold for AccessPassExperience bridge
- **Note**: Build the right architecture from the start

## ✅ Simplified Phase 1 Implementation (4 Weeks)

### Week 1: Core Models & Foundation

```bash
# Day 1-2: Core marketplace models
rails generate super_scaffold Space Team name:text_field slug:text_field description:trix_editor
rails generate super_scaffold Experience Space name:text_field description:trix_editor experience_type:options{live_stream,course,community}
rails generate super_scaffold AccessPass Space name:text_field price:number_field pricing_type:options{free,one_time,monthly}

# Day 3-4: Streaming models
rails generate super_scaffold Stream Experience title:text_field scheduled_at:date_and_time_field status:options{scheduled,live,ended}

# Day 5: Set up relationships and validations
# - Team has_many :spaces (but UI shows one)
# - Space has_many :experiences
# - Space has_many :access_passes
# - Experience has_many :streams
```

### Week 2: Purchase Flow with Passwordless Auth

```bash
# Day 1: 6-digit OTP authentication
rails generate super_scaffold AuthCode User code:text_field purpose:options{login,signup} expires_at:date_and_time_field

# Day 2-3: Purchase model and Stripe setup
rails generate super_scaffold Billing::Purchase AccessPass,User amount:number_field stripe_charge_id:text_field

# Day 4: Stripe Checkout or Elements (your choice)
# - Stripe Checkout for speed OR
# - Stripe Elements for custom UI

# Day 5: Access control
# - Purchase creates active AccessPass
# - AccessPass grants Experience access
```

### Week 3: Basic Streaming

```bash
# Day 1-2: LiveKit integration
# - Room creation for streams
# - Token generation for hosts/viewers
# - Basic WebRTC setup

# Day 3: Simple chat with LiveKit
# - Use LiveKit data channels
# - Text messages only
# - No moderation for MVP

# Day 4-5: Access verification
# - Check AccessPass before stream entry
# - Host can always access their streams
# - Basic recording to S3/R2
```

### Week 4: Polish & Deploy

```bash
# Day 1-2: Essential features only
# - Email notifications (purchase, stream starting)
# - Basic creator dashboard (revenue, viewer count)
# - Error handling

# Day 3-4: Testing
# - Core purchase flow
# - Stream access control
# - Recording functionality

# Day 5: Production deployment
# - Kamal 2 or Heroku
# - Environment variables
# - Basic monitoring
```

## 📊 Realistic Model Structure

### Simplified for MVP

```ruby
# app/models/space.rb
class Space < ApplicationRecord
  belongs_to :team
  has_many :experiences
  has_many :access_passes
  has_many :streams, through: :experiences
  
  # Simple pricing for MVP
  monetize :price_cents
  enum pricing_type: { free: 0, one_time: 1, monthly: 2 }
end

# app/models/access_pass.rb  
class AccessPass < ApplicationRecord
  belongs_to :space
  belongs_to :user
  has_one :purchase, class_name: 'Billing::Purchase'
  
  # Simple active/inactive for MVP
  scope :active, -> { where(active: true) }
  
  # No complex Experience selection yet
  def includes_experience?(experience)
    experience.space_id == space_id
  end
end

# app/models/experience.rb
class Experience < ApplicationRecord
  belongs_to :space
  has_many :streams
  
  enum experience_type: { 
    live_stream: 0,
    course: 1,
    community: 2 
  }
end

# app/models/stream.rb
class Stream < ApplicationRecord
  belongs_to :experience
  belongs_to :host, class_name: 'User'
  
  enum status: { scheduled: 0, live: 1, ended: 2 }
  
  def can_view?(user)
    return true if host == user
    user.access_passes.active.where(space_id: experience.space_id).exists?
  end
end
```

## 🚀 Week 1 Implementation Checklist

### Day 1: Setup & First Model
- [ ] Verify Rails 8 + Bullet Train setup
- [ ] Run pre-flight checks
- [ ] Generate Space model with super_scaffold
- [ ] Set up Team → Space relationship
- [ ] Create basic Space controller

### Day 2: Experience & AccessPass
- [ ] Generate Experience model
- [ ] Generate AccessPass model (simple version)
- [ ] Set up associations
- [ ] Create basic CRUD controllers

### Day 3: Stream Model & Relationships
- [ ] Generate Stream model
- [ ] Set up all model relationships
- [ ] Add FriendlyId for slugs
- [ ] Create seeds.rb for test data

### Day 4: Public Pages
- [ ] Create Public::SpacesController
- [ ] Build Space sales page view
- [ ] Add AccessPass purchase button
- [ ] Style with Tailwind

### Day 5: Access Control
- [ ] Implement basic CanCan abilities
- [ ] Create purchased_spaces scope
- [ ] Test access control
- [ ] Document patterns

## ⚠️ What We're NOT Building in Phase 1

### Deferred to Phase 2+
- ❌ Passwordless authentication
- ❌ Complex AccessPass → Experience selection
- ❌ Waitlist approval workflows
- ❌ Stripe Elements custom checkout
- ❌ GetStream.io chat
- ❌ Native mobile apps
- ❌ Creator profiles (/@username)
- ❌ Advanced analytics
- ❌ Clip generation
- ❌ Multi-streaming

### Why This Approach Works

1. **Framework Compliance**: Works WITH Bullet Train, not against it
2. **Faster Development**: 4 weeks achievable vs 6-8 weeks original
3. **Lower Costs**: LiveKit only ($500-3000/month) vs LiveKit + GetStream ($1000-5000/month)
4. **Incremental Complexity**: Start simple, add features based on user feedback
5. **Core Value Focus**: Creator sells access, viewer pays and watches

## 🎯 Success Metrics (Achievable)

### Week 1
- [ ] All core models created and related
- [ ] Basic CRUD working
- [ ] Seeds.rb creates test data

### Week 2  
- [ ] User can purchase AccessPass with Stripe Checkout
- [ ] Purchase creates active AccessPass
- [ ] User can see purchased Spaces

### Week 3
- [ ] Creator can start live stream
- [ ] Viewers with AccessPass can watch
- [ ] Basic chat working

### Week 4
- [ ] Deployed to production
- [ ] First real purchase processed
- [ ] First real stream hosted

## Next Immediate Steps

```bash
# 1. Acknowledge simplified plan
cat PHASE1_REVISED.md

# 2. Generate first model
rails generate super_scaffold Space Team \
  name:text_field \
  slug:text_field \
  description:trix_editor \
  price:number_field \
  pricing_type:options{free,one_time,monthly}

# 3. Run migrations
rails db:migrate

# 4. Verify in console
rails console
> Team.first.create_space!(name: "Test Space")
```

This revised plan is achievable, works with Bullet Train's patterns, and delivers core marketplace value in 4 weeks.