# Ready to Build - Architecture Finalized

## ✅ Architecture Decisions Confirmed

### 1. Authentication
- **Public**: 6-digit OTP passwordless (custom implementation)
- **Team Members**: Standard Devise (Bullet Train default)
- **Implementation**: AuthCode model with super_scaffold

### 2. Team/Space Relationship  
- **Database**: Team `has_many :spaces`
- **Phase 1 UX**: One Space per Team (validated)
- **Auto-creation**: Space created with Team
- **Future**: Remove validation for multi-Space

### 3. Public Routes (Critical Understanding)
- **NO team context needed** for public routes
- Clean URLs: `/@username`, `/space-slug`
- Direct database lookups, not team-scoped
- Standard Rails practice, Bullet Train expects this

### 4. Model Namespacing
- **Primary Subjects** (global): Space, Experience, AccessPass, Stream
- **Supporting Models** (namespaced): Creators::Profile, Billing::Purchase, AccessPasses::WaitlistEntry
- **Validation Script**: Run before any super_scaffold command

### 5. Chat Implementation
- **Option A**: LiveKit data channels (free with video)
- **Option B**: GetStream.io (better features, extra cost)
- Start with A, upgrade to B if needed

### 6. AccessPass Complexity
- Not simple polymorphic relationship
- Needs Experience selection via join table
- Complex pricing options (free, one-time, recurring)
- Waitlist functionality built-in

## 🚀 Week 1 Implementation Order

### Day 1: Foundation Models

```bash
# 1. Validate and create Space model
ruby .claude/validate-namespacing.rb "rails generate super_scaffold Space Team name:text_field"
rails generate super_scaffold Space Team \
  name:text_field \
  slug:text_field \
  description:trix_editor \
  published:boolean

# 2. Create Experience model  
rails generate super_scaffold Experience Space,Team \
  name:text_field \
  description:trix_editor \
  experience_type:options{live_stream,course,community}

# 3. Create AccessPass model (complex version)
rails generate super_scaffold AccessPass Space,Team \
  name:text_field \
  description:trix_editor \
  pricing_type:options{free,one_time,recurring} \
  initial_fee:number_field \
  recurring_price:number_field \
  stock_remaining:number_field \
  waitlist_enabled:boolean

# 4. Create bridge model
rails generate super_scaffold AccessPassExperience AccessPass,Experience \
  included:boolean \
  ordinal_position:number_field
```

### Day 2: Passwordless Authentication

```bash
# 1. Create AuthCode model
rails generate super_scaffold AuthCode User \
  code:text_field \
  identifier:text_field \
  purpose:options{login,signup,purchase} \
  expires_at:date_and_time_field \
  consumed_at:date_and_time_field

# 2. Create public auth controllers
rails generate controller public/auth/sessions new send_code verify authenticate
```

### Day 3: Public Routes & Controllers

```bash
# 1. Create public controllers
rails generate controller public/spaces index show
rails generate controller public/access_passes show
rails generate controller public/creator_profiles show

# 2. Set up routes
# Add to config/routes.rb as documented in PUBLIC_ROUTES_ARCHITECTURE.md
```

### Day 4: Streaming Models

```bash
# 1. Create Stream model
rails generate super_scaffold Stream Experience,Team \
  title:text_field \
  description:trix_editor \
  scheduled_at:date_and_time_field \
  status:options{scheduled,live,ended} \
  room_name:text_field \
  recording_url:text_field

# 2. Create supporting models
rails generate super_scaffold Streaming::Participant Stream,User \
  role:options{host,moderator,viewer} \
  joined_at:date_and_time_field
```

### Day 5: Relationships & Validations

```ruby
# app/models/team.rb
class Team < ApplicationRecord
  include Teams::Base
  
  has_one :space, dependent: :destroy  # UI shows one
  # has_many :spaces in future
  
  after_create :create_default_space
  
  private
  
  def create_default_space
    create_space!(
      name: name,
      slug: slug.presence || name.parameterize,
      published: false
    )
  end
end

# app/models/space.rb  
class Space < ApplicationRecord
  include Spaces::Base
  
  belongs_to :team
  has_many :experiences
  has_many :access_passes
  
  validates :team_id, uniqueness: true  # One per team for now
  
  extend FriendlyId
  friendly_id :slug, use: :slugged
end

# app/models/access_pass.rb
class AccessPass < ApplicationRecord
  include AccessPasses::Base
  
  belongs_to :space
  has_many :access_pass_experiences
  has_many :experiences, through: :access_pass_experiences
  has_many :purchases, class_name: 'Billing::Purchase'
  
  scope :available, -> { where('stock_remaining > 0 OR stock_remaining IS NULL') }
  scope :published, -> { where(published: true) }
  
  def includes_experience?(experience)
    experiences.include?(experience)
  end
end
```

## 🎯 Success Metrics for Week 1

### Must Have
- [ ] All models created and migrated
- [ ] Relationships working in console
- [ ] Seeds.rb creates test data
- [ ] Public space page loads
- [ ] Passwordless auth sends codes

### Nice to Have  
- [ ] Basic Tailwind styling
- [ ] Space admin CRUD working
- [ ] Purchase button shows

### Can Wait
- [ ] Stripe integration
- [ ] LiveKit setup
- [ ] Email sending
- [ ] Production deployment

## Common Commands Reference

```bash
# Check namespacing before creating models
ruby .claude/validate-namespacing.rb "your command"

# Run pre-flight checks
bash .claude/pre-flight.sh

# Generate with super_scaffold
rails generate super_scaffold ModelName ParentModel field:type

# Test in console
rails console
> Team.create!(name: "Test Team")
> team = Team.first
> team.primary_space
> space = team.space
> space.experiences.create!(name: "Live Stream")

# Run tests
rails test
rails test:system

# Start dev server
bin/dev
```

## What NOT to Build Yet

### Defer to Week 2+
- Stripe Checkout/Elements
- LiveKit video integration  
- GetStream.io chat
- Email notifications
- Complex waitlist workflows
- Creator profiles (/@username)
- Mobile apps

### Keep It Simple
- Start with core models
- Get relationships right
- Build public pages
- Test passwordless auth
- Then add complexity

## Architecture is Now Clear

We have resolved:
1. ✅ Passwordless is possible (custom 6-digit OTP)
2. ✅ Public routes don't need team context
3. ✅ Team/Space relationship (one initially, many later)
4. ✅ Model namespacing rules (Culver's patterns)
5. ✅ AccessPass complexity understood
6. ✅ Streaming architecture planned

**Ready to start building Week 1 Day 1!**