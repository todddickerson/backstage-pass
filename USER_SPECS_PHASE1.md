# Phase 1 MVP User Specifications

## Executive Summary

Phase 1 MVP delivers a functional marketplace where creators can sell access passes to live streaming experiences. Core functionality includes: creator spaces, access pass sales, live streaming with chat, and basic content management.

**MVP Goal:** Enable creators to monetize live streams through paid access passes with a complete viewer experience.

## User Roles

### 1. Creator (Space Owner)
- Creates and manages Spaces
- Defines Access Passes with pricing
- Hosts live streams
- Manages waitlists (manual approval)
- Views basic analytics

### 2. Viewer/Buyer
- Discovers Spaces and creators
- Purchases Access Passes
- Watches live streams
- Participates in chat
- Manages purchased content

### 3. Platform Admin
- Manages platform settings
- Handles support issues
- Reviews content flags
- Manages creator accounts

## User Stories & Acceptance Criteria

### 🎭 Creator Stories

#### STORY 1: Creator Onboarding
**As a** creator  
**I want to** set up my creator profile and first Space  
**So that** I can start selling access to my content

**Acceptance Criteria:**
- [ ] Can create creator profile with username (/@username route)
- [ ] Can create first Space with name, description, cover image
- [ ] Can set Space slug for public URL
- [ ] Can configure Space brand colors and welcome message
- [ ] Space has public sales page at /space-slug

**Technical Requirements:**
- CreatorProfile model with FriendlyId
- Space model belongs to Team (Bullet Train context)
- Space has_many :experiences through AccessPasses
- Public::SpacesController for sales pages

#### STORY 2: Access Pass Creation
**As a** creator  
**I want to** create different tiers of access passes  
**So that** I can offer various pricing options

**Acceptance Criteria:**
- [ ] Can create multiple Access Passes per Space
- [ ] Can set pricing (free, one-time, monthly, yearly)
- [ ] Can select which Experiences are included in each pass
- [ ] Can set stock limits and expiration
- [ ] Can enable waitlist with custom questions
- [ ] Can preview sales page for each Access Pass

**Technical Requirements:**
- AccessPass model with complex pricing structure
- AccessPassExperience join table
- Monetize gem for price fields
- Stripe Elements for payment processing

#### STORY 3: Live Stream Hosting
**As a** creator  
**I want to** host live streams for my paying audience  
**So that** I can deliver exclusive content

**Acceptance Criteria:**
- [ ] Can schedule a stream with title and description
- [ ] Can go live with webcam and screen share
- [ ] Can see viewer count and chat
- [ ] Can moderate chat (delete messages, ban users)
- [ ] Can end stream and it saves as recording
- [ ] Only users with valid Access Pass can view

**Technical Requirements:**
- LiveKit integration for WebRTC streaming
- GetStream.io for chat functionality
- Stream model with status states
- Recording to Cloudflare R2

#### STORY 4: Waitlist Management
**As a** creator  
**I want to** review and approve waitlist applications  
**So that** I can control who gets access

**Acceptance Criteria:**
- [ ] Can view pending waitlist entries
- [ ] Can see applicant answers to custom questions
- [ ] Can approve or reject applications one by one
- [ ] Approved users receive email with access instructions
- [ ] Can see history of approved/rejected applications

**Technical Requirements:**
- WaitlistEntry model with status enum
- Account::WaitlistEntriesController
- Email notifications on approval
- Manual approval only (no bulk for MVP)

#### STORY 5: Basic Analytics
**As a** creator  
**I want to** see how my content is performing  
**So that** I can make informed decisions

**Acceptance Criteria:**
- [ ] Can see total revenue
- [ ] Can see number of active Access Passes
- [ ] Can see stream viewer counts
- [ ] Can see chat engagement metrics
- [ ] Data refreshes daily (not real-time)

**Technical Requirements:**
- Basic Rails counter caches
- Daily background job for aggregation
- Simple dashboard views

### 👀 Viewer/Buyer Stories

#### STORY 6: Space Discovery
**As a** viewer  
**I want to** discover interesting Spaces  
**So that** I can find content worth purchasing

**Acceptance Criteria:**
- [ ] Can browse public Space pages
- [ ] Can view creator profiles at /@username
- [ ] Can see Space description and available Access Passes
- [ ] Can preview what's included in each Access Pass
- [ ] Can see pricing clearly displayed

**Technical Requirements:**
- Public controllers outside authentication
- SEO-friendly URLs with slugs
- No advanced search (basic filtering only)

#### STORY 7: Access Pass Purchase
**As a** viewer  
**I want to** purchase an Access Pass  
**So that** I can access exclusive content

**Acceptance Criteria:**
- [ ] Can click "Get Access" on any Access Pass
- [ ] If not logged in, enter email for passwordless auth
- [ ] Receive 6-digit code via email
- [ ] Complete purchase with credit card (Stripe Elements)
- [ ] Immediately redirected to purchased content
- [ ] Receive email confirmation

**Technical Requirements:**
- Passwordless authentication system
- One-time password (OTP) via email
- Stripe Elements integration
- Purchase model for transactions
- Automatic AccessPass activation

#### STORY 8: Live Stream Viewing
**As a** viewer with access  
**I want to** watch live streams  
**So that** I can consume the content I paid for

**Acceptance Criteria:**
- [ ] Can see upcoming and live streams in my purchased Spaces
- [ ] Can join live stream with one click
- [ ] Video plays smoothly with adaptive quality
- [ ] Can participate in chat
- [ ] Can use reactions/emojis
- [ ] Can full-screen the video

**Technical Requirements:**
- Account::PurchasedSpacesController
- Account::ExperiencesController
- LiveKit WebRTC for video
- GetStream.io for chat
- Mobile: Native video players (not web)

#### STORY 9: Waitlist Application
**As a** viewer  
**I want to** apply to exclusive Spaces with waitlists  
**So that** I can potentially gain access

**Acceptance Criteria:**
- [ ] Can see "Join Waitlist" instead of purchase button
- [ ] Can answer required custom questions
- [ ] Receive confirmation email after applying
- [ ] Get notified via email if approved
- [ ] Can proceed to payment after approval

**Technical Requirements:**
- WaitlistEntry creation in public context
- Store answers as JSONB
- Email notifications via ActionMailer
- Status tracking (pending/approved/rejected)

#### STORY 10: Account Management
**As a** viewer  
**I want to** manage my purchased Access Passes  
**So that** I can track what I have access to

**Acceptance Criteria:**
- [ ] Can see all purchased Access Passes
- [ ] Can see expiration dates
- [ ] Can cancel recurring subscriptions
- [ ] Can update payment method
- [ ] Can download receipts

**Technical Requirements:**
- Account::AccessPassesController
- Stripe Customer Portal integration
- Invoice/receipt generation

## Technical Specifications

### Required Integrations
```yaml
# config/application.yml (already added by user)
STRIPE_PUBLISHABLE_KEY: pk_test_xxx
STRIPE_SECRET_KEY: sk_test_xxx

LIVEKIT_API_KEY: xxx
LIVEKIT_API_SECRET: xxx
LIVEKIT_URL: wss://xxx

GETSTREAM_API_KEY: xxx
GETSTREAM_API_SECRET: xxx

MUX_TOKEN_ID: xxx
MUX_TOKEN_SECRET: xxx
```

### Database Models (Phase 1)

```ruby
# Core Models Required
- User (Bullet Train)
- Team (Bullet Train)
- Membership (Bullet Train)
- CreatorProfile (NEW)
- Space (NEW)
- AccessPass (NEW)
- AccessPassExperience (NEW)
- Experience (NEW)
- Stream (NEW)
- Purchase (NEW)
- WaitlistEntry (NEW)

# Relationships
Team has_many :spaces
Space has_many :access_passes
Space has_many :experiences
AccessPass has_many :access_pass_experiences
AccessPass has_many :experiences, through: :access_pass_experiences
User has_many :purchases
User has_many :access_passes, through: :purchases
```

### Controllers Structure

```
app/controllers/
├── public/
│   ├── creator_profiles_controller.rb  # /@username
│   ├── spaces_controller.rb            # /space-slug
│   ├── access_passes_controller.rb     # /space-slug/pass-slug
│   └── purchases_controller.rb         # Checkout flow
├── account/
│   ├── purchased_spaces_controller.rb  # Member area
│   ├── experiences_controller.rb       # Stream viewing
│   ├── access_passes_controller.rb     # Manage purchases
│   ├── spaces_controller.rb            # Creator management
│   ├── streams_controller.rb           # Creator streaming
│   └── waitlist_entries_controller.rb  # Approve/reject
└── api/v1/
    └── (Phase 2)
```

## Out of Scope for Phase 1

### ❌ NOT Included in MVP

1. **Advanced Search & Discovery**
   - No vector database search
   - No AI recommendations
   - No trending/featured algorithms
   - Basic category filtering only

2. **Creator Monetization**
   - No creator payouts
   - No revenue splitting
   - No tax handling
   - Platform owns all revenue

3. **Advanced Payment Features**
   - No split payments
   - No payment plans
   - No free trials (just free/paid)
   - No refund automation

4. **Social Features**
   - No follower/following system
   - No private messaging
   - No user profiles (only creator profiles)
   - No comments on streams

5. **Advanced Streaming**
   - No multi-streaming to YouTube/Twitch
   - No stream scheduling UI (manual only)
   - No clip generation
   - No highlight detection

6. **Mobile Apps**
   - Web-responsive only
   - Hotwire Native wrapper possible but not required
   - No app store submissions

7. **Analytics & Reporting**
   - No real-time analytics
   - No export features
   - No creator dashboard (basic stats only)
   - No viewer analytics

8. **Moderation Scale**
   - No AI content moderation
   - No bulk moderation tools
   - Manual review only
   - Basic GetStream.io filters only

## Success Metrics (Phase 1)

### Technical Success
- [ ] All user stories completed
- [ ] All acceptance criteria passing
- [ ] Test coverage > 80%
- [ ] Page load < 2 seconds
- [ ] Stream latency < 3 seconds
- [ ] Zero critical security issues

### Business Success (Post-Launch)
- [ ] 10 creators onboarded
- [ ] 100 Access Passes sold
- [ ] 5 successful live streams
- [ ] < 5% payment failure rate
- [ ] < 10% support ticket rate

## Development Checkpoints

### Checkpoint 1: Models & Auth (Week 1)
- [ ] CreatorProfile model working
- [ ] Space model with public pages
- [ ] AccessPass with pricing
- [ ] Passwordless auth functioning

### Checkpoint 2: Purchase Flow (Week 2)
- [ ] Stripe Elements integrated
- [ ] Purchase flow complete
- [ ] Access control working
- [ ] Waitlist applications working

### Checkpoint 3: Streaming (Week 3)
- [ ] LiveKit streaming working
- [ ] GetStream.io chat integrated
- [ ] Access verification for streams
- [ ] Basic moderation tools

### Checkpoint 4: Polish (Week 4)
- [ ] Email notifications
- [ ] Basic analytics
- [ ] Error handling
- [ ] Production deployment

## Questions for Clarification

1. **Stream Recordings**
   - Should all streams auto-record or creator choice?
   - How long to retain recordings?
   - Download enabled for viewers?

2. **Waitlist Limits**
   - Maximum waitlist size per Access Pass?
   - Expiration for pending applications?
   - Re-application allowed after rejection?

3. **Subscription Management**
   - Grace period for failed payments?
   - Dunning email sequence?
   - Upgrade/downgrade between passes allowed?

4. **Content Policies**
   - DMCA handling process?
   - Prohibited content list?
   - Strike system for violations?

## Ready for Implementation?

### ✅ Clear Requirements
- User stories defined
- Technical architecture decided
- Integrations identified
- Database schema planned

### ⚠️ Needs Clarification
- Recording retention policy
- Waitlist limitations
- Content moderation policies

### 🚀 Recommended Starting Point

1. **Set up integrations first**
   ```bash
   # Add to Gemfile
   gem 'stream-chat-ruby'
   gem 'livekit-server-sdk'
   gem 'stripe'
   gem 'money-rails'
   
   bundle install
   ```

2. **Create CreatorProfile model**
   ```bash
   rails generate super_scaffold CreatorProfile User username:text_field bio:text_area
   ```

3. **Create Space model**
   ```bash
   rails generate super_scaffold Space Team name:text_field slug:text_field description:trix_editor
   ```

---

**STOP POINT**: Review this specification before proceeding with implementation. Confirm all user stories align with business goals and technical capabilities.