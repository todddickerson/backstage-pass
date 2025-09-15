# Phase 1 MVP User Specifications

## Executive Summary

Phase 1 MVP delivers a functional marketplace where creators can sell access passes to live streaming experiences. Core functionality includes: creator spaces, access pass sales, live streaming with chat, and basic content management. **Phase 1b adds native iOS and Android apps** with superior streaming performance through Hotwire Native and native video players.

**MVP Goal:** Enable creators to monetize live streams through paid access passes with a complete viewer experience across web and mobile platforms.

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

## Phase 1b: Hotwire Native Mobile Apps

### Overview
Native iOS and Android apps using Hotwire Native wrappers with native video players for LiveKit streaming. Delivers superior streaming performance compared to web-only experience.

### 📱 Mobile-Specific User Stories

#### STORY 11: Mobile App Installation
**As a** viewer  
**I want to** download the Backstage Pass mobile app  
**So that** I can have a better streaming experience

**Acceptance Criteria:**
- [ ] Can install iOS app via TestFlight
- [ ] Can install Android app via internal testing  
- [ ] App opens to Space discovery screen
- [ ] Can sign in with email (passwordless)
- [ ] Receives push notifications for streams

**Technical Requirements:**
- Hotwire Native iOS wrapper (Swift)
- Hotwire Native Android wrapper (Kotlin)
- Push notification setup (Firebase/APNS)
- Native authentication bridge

#### STORY 12: Native Video Streaming
**As a** mobile viewer  
**I want to** watch streams with native video players  
**So that** I get optimal performance and battery life

**Acceptance Criteria:**
- [ ] Native video player launches for streams
- [ ] Video continues in background (audio only)
- [ ] Picture-in-picture mode supported
- [ ] Screen rotation handled natively
- [ ] Low latency (<2 seconds)
- [ ] Adaptive bitrate for mobile networks

**Technical Requirements:**
- LiveKit iOS SDK integration
- LiveKit Android SDK integration  
- JavaScript bridge for player control
- Native player UI components
- Background audio permissions

#### STORY 13: Mobile Chat Experience
**As a** mobile viewer  
**I want to** participate in chat while watching  
**So that** I can engage with the community

**Acceptance Criteria:**
- [ ] Chat renders in web view (GetStream.io)
- [ ] Keyboard doesn't cover chat input
- [ ] Can send messages and reactions
- [ ] Smooth scrolling performance
- [ ] Notifications for mentions

**Technical Requirements:**
- GetStream.io JavaScript SDK
- Keyboard handling in native wrapper
- Web/native communication bridge
- Push notifications for mentions

### Mobile Technical Architecture

#### iOS Implementation
```swift
// Hotwire Native Configuration
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func configureRootViewController() -> UIViewController {
        let navigator = Navigator()
        navigator.delegate = self
        
        // Register native video player route
        navigator.route("/account/*/experiences/*/stream") { _ in
            return LiveKitVideoViewController()
        }
        
        return navigator.rootViewController
    }
}

// Native LiveKit Player
class LiveKitVideoViewController: UIViewController {
    private let room = LiveKitRoom()
    
    func connect(token: String, url: String) {
        room.connect(url, token) { [weak self] in
            self?.setupVideoView()
        }
    }
}
```

#### Android Implementation
```kotlin
// Hotwire Native Configuration
class MainActivity : HotwireActivity() {
    override fun registeredActivities(): List<KClass<out HotwireActivity>> {
        return listOf(
            LiveStreamActivity::class
        )
    }
    
    override fun registeredFragments(): List<KClass<out HotwireFragment>> {
        return listOf(
            WebFragment::class,
            LiveKitFragment::class
        )
    }
}

// Native LiveKit Player
class LiveKitFragment : Fragment() {
    private lateinit var room: LiveKitRoom
    
    fun connect(token: String, url: String) {
        room = LiveKitRoom(requireContext())
        room.connect(url, token)
    }
}
```

#### JavaScript Bridge
```javascript
// app/javascript/bridges/native_video.js
export class NativeVideoBridge {
  static connect(element) {
    const platform = element.dataset.platform
    const streamData = {
      token: element.dataset.livekitToken,
      url: element.dataset.livekitUrl,
      streamId: element.dataset.streamId
    }
    
    if (window.HotwireNative) {
      // Send to native player
      window.HotwireNative.playStream(streamData)
    } else {
      // Fallback to web player
      new WebStreamPlayer(element, streamData)
    }
  }
}

// Register with Stimulus
import { Application } from "@hotwired/stimulus"
const application = Application.start()
application.register("native-video", NativeVideoBridge)
```

### Mobile-Specific Features

#### Background Capabilities
- **iOS**: Background audio mode for continued playback
- **Android**: Foreground service for streaming
- **Both**: Picture-in-picture for video

#### Push Notifications
```ruby
# app/jobs/mobile_notification_job.rb
class MobileNotificationJob < ApplicationJob
  def perform(user, event_type, data)
    return unless user.push_tokens.any?
    
    case event_type
    when :stream_starting
      send_notification(
        user.push_tokens,
        title: "#{data[:creator_name]} is going live!",
        body: data[:stream_title],
        data: { 
          type: 'stream',
          stream_id: data[:stream_id],
          deep_link: "/account/purchased_spaces/#{data[:space_id]}/experiences/#{data[:experience_id]}/stream"
        }
      )
    when :purchase_complete
      send_notification(
        user.push_tokens,
        title: "Welcome to #{data[:space_name]}!",
        body: "Your access pass is ready",
        data: { 
          type: 'purchase',
          space_id: data[:space_id]
        }
      )
    end
  end
  
  private
  
  def send_notification(tokens, payload)
    # Firebase for Android
    fcm_tokens = tokens.select { |t| t.platform == 'android' }
    Firebase.send_multicast(fcm_tokens, payload) if fcm_tokens.any?
    
    # APNS for iOS
    apns_tokens = tokens.select { |t| t.platform == 'ios' }
    APNS.send_notifications(apns_tokens, payload) if apns_tokens.any?
  end
end
```

### Mobile Development Requirements

#### Environment Setup
```yaml
# iOS Requirements
- Xcode 15+
- iOS 15.0+ deployment target
- Swift 5.9+
- CocoaPods or SPM for dependencies

# Android Requirements  
- Android Studio Hedgehog+
- minSdk 24 (Android 7.0)
- targetSdk 34 (Android 14)
- Kotlin 1.9+
- Gradle 8.0+
```

#### Dependencies
```ruby
# Gemfile additions for mobile support
gem 'rpush' # Push notifications
gem 'device_detector' # Detect mobile platforms

# iOS Podfile
pod 'LiveKit'
pod 'HotwireNative'

# Android build.gradle
implementation 'io.livekit:livekit-android:1.5.0'
implementation 'dev.hotwire:turbo:7.0.0'
```

### Mobile Testing Strategy

#### Device Testing Matrix
- **iOS**: iPhone 12+ (all sizes), iPad support optional
- **Android**: Pixel 6+, Samsung Galaxy S21+
- **OS Versions**: iOS 15-17, Android 10-14
- **Network**: 3G, 4G, 5G, WiFi conditions

#### Mobile-Specific Test Cases
1. Stream playback in various network conditions
2. Background audio continuation
3. App backgrounding/foregrounding during stream
4. Push notification delivery and deep linking
5. Native player performance metrics
6. Battery usage monitoring

### Phase 1b Timeline (Additional 2 weeks)

#### Week 5: iOS App
- [ ] Hotwire Native iOS setup
- [ ] LiveKit iOS SDK integration
- [ ] Native video player implementation
- [ ] Push notifications (APNS)
- [ ] TestFlight deployment

#### Week 6: Android App
- [ ] Hotwire Native Android setup
- [ ] LiveKit Android SDK integration
- [ ] Native video player implementation
- [ ] Push notifications (Firebase)
- [ ] Internal testing release

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

6. **App Store Submissions** 
   - No app store submissions in Phase 1
   - TestFlight/internal testing only
   - App store submission in Phase 2

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

### Phase 1: Web Platform (Weeks 1-4)

#### Checkpoint 1: Models & Auth (Week 1)
- [ ] CreatorProfile model working
- [ ] Space model with public pages
- [ ] AccessPass with pricing
- [ ] Passwordless auth functioning

#### Checkpoint 2: Purchase Flow (Week 2)
- [ ] Stripe Elements integrated
- [ ] Purchase flow complete
- [ ] Access control working
- [ ] Waitlist applications working

#### Checkpoint 3: Streaming (Week 3)
- [ ] LiveKit streaming working
- [ ] GetStream.io chat integrated
- [ ] Access verification for streams
- [ ] Basic moderation tools

#### Checkpoint 4: Polish (Week 4)
- [ ] Email notifications
- [ ] Basic analytics
- [ ] Error handling
- [ ] Production deployment

### Phase 1b: Mobile Apps (Weeks 5-6)

#### Checkpoint 5: iOS App (Week 5)
- [ ] Hotwire Native iOS wrapper
- [ ] LiveKit native player integrated
- [ ] Push notifications working
- [ ] TestFlight build available
- [ ] Background audio working

#### Checkpoint 6: Android App (Week 6)
- [ ] Hotwire Native Android wrapper
- [ ] LiveKit native player integrated
- [ ] Firebase notifications working
- [ ] Internal testing build available
- [ ] Picture-in-picture working

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
   gem 'rpush'              # For mobile push notifications
   gem 'device_detector'    # For platform detection
   
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

4. **Initialize mobile apps (Phase 1b)**
   ```bash
   # iOS App
   rails generate hotwire:native:ios
   cd ios && pod install
   
   # Android App  
   rails generate hotwire:native:android
   cd android && ./gradlew build
   ```

---

**Timeline Summary:**
- **Phase 1 (Weeks 1-4):** Web platform with full functionality
- **Phase 1b (Weeks 5-6):** Native iOS and Android apps with superior streaming
- **Total Duration:** 6 weeks to production-ready web + mobile

**STOP POINT**: Review this specification before proceeding with implementation. Confirm all user stories align with business goals and technical capabilities.