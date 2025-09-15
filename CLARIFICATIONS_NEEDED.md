# Backstage Pass - Clarifications & Design Decisions Needed

## 🔴 Critical Questions (Block Development)

### 1. **AccessPass Polymorphic Design**
**Issue**: AccessPass has `belongs_to :purchasable, polymorphic: true` for both Space and Experience
**Questions**:
- Should users be able to buy a Space pass that includes ALL experiences?
- Can experiences override Space pass pricing?
- How do we handle nested access (Space pass vs individual Experience pass)?
- What happens when a user has both a Space pass AND an Experience pass?

Answer: An access pass should always give access to the parent space and should give access to a selected list of experiences that can be toggled on and off by the user. For example, a basic or a pro plan might include access to a chat experience, whereas the pro plan might also include access to a premium live stream.  We should also have multiple pricing options available for access passes. For example, we might have a $1/month plan or a $10/year plan. 

Free OR Onetime OR Recurring prices

Some of the options for pricing that we need to consider:
- Initial fee
- Number in stock
- Whether or not it includes a free trial and if so, for how long
- Whether or not split pay payments are available and how many of them to allow  Additionally, we might want to offer a discount on cancellation, ask additional questions before checkout, redirect after checkout, and add an internal name that is not visible to users. We also want to give options for toggling payment methods that will correlate to Stripe elements payment methods.
- Redirect after checkout
- "Add a waitlist" which requires 
```Whop waitlists allow sellers to control who gets access to their product or community by requiring users to apply and wait for approval before admission. Users join the waitlist through a checkout link, and the seller can approve, reject, or collect more information from applicants before unlocking access.

How Whop Waitlists Work
Application Process: Users find a product listed with a waitlist option and submit their details, often answering custom questions set by the seller to help assess whether they’re a good fit.

Seller Review: The seller reviews each entry via the Whop dashboard, where they can individually approve or deny applicants, or admit all at once.

Notifications & Access: Once approved, the user gets immediate access and receives a notification. If denied, they do not gain access.

Managing Waitlists: Sellers can export waitlist data, contact users, and set options like access expiry or redirect URLs after approval.

Key Features for Sellers
Custom Questions: Sellers can add mandatory or optional questions applicants must answer to join the waitlist, helping qualify leads.

Exclusivity and Control: Waitlists build anticipation, foster exclusivity, and allow for controlled beta launches or gated communities.

Automation Options: Sellers may admit all entries at once, export the list, or message applicants directly from the dashboard.
```

For free options on pricing, we want to also have an auto-expire access option to give the users the ability to expire access after X number of days (7 days for example)

EXAMPLE but must be dynamic.
```
Select which apps users will get access to after purchase
Livestreaming A boolean
Chat boolean
Livesteaming B boolean
```

Important Note: right now "Livestreaming" is our primary use case but we must build planning for all kinds of other 'app' experiences such as Chat, custom apps, website iframes/embeds, etc




### 2. **Team vs Creator Context**
**Issue**: Bullet Train uses Team as the account context, but we need creator profiles
**Questions**:
- Is a Space owned by a Team or a User (creator)?
- Can a Team have multiple Spaces (multi-brand)?
- How do creators manage their Spaces (separate from Team admin)?
- Do we need a Creator model between User and Space?

Answer: We should have Teams own things like Spaces but Users have their own personal Creator profiles that live outside the team (if a user leaves a team they still have a creator profile) Note that MEMBERSHIPS live forever even after a user leaves a team so there is a record of them we can reference from team views as a membership. Team <> Membership <> User < CreatorProfile

I want creator profiles to live at backstagepass.com/@creatorname

I want spaces to live at backstagepass.com/space-name (Public::) route w/ a 'sales page' for the Space listing AccessPasses Available to purchase.  
  This page should show the content for the selected AccessPass (defaulting to whichever is set as default by user by using sortable super scaffold) it should dynamically show the below access pass details when selected. 

AccessPasses have their own version of the sales page at backstagepass.com/space-name/accesspass-name (Public::)
  This page should allow user to customize:
  - Headline, category, description
  - Media/images
  - list of features/benefits
  - FAQ items (question/answer)
Clicking "Join" should either grant immediate access if free or open a checkout/purchase modal (stripe payment elements) if paid then redirect to the experience
  
When logged in as a team user with edit access the sales page should allow customizing these elements inline on the page w/ edit in place/refresh on changes.

Experiences should live at routes like this:
(m == "member view" route)
backstagepass.com/m/space-name/ -> redirects to backstagepass.com/m/space-name/experience-name (first experience in sortable list of possible experiences for Space)



### 3. **Public vs Account Namespaces**
**Issue**: Unclear when to use Public:: vs Account:: controllers
**Questions**:
- Public marketplace browsing: `Public::SpacesController` or `SpacesController`?
- Purchase flow: Public or Account namespace?
- Stream viewing: Requires auth but not team context - which namespace?

Answer:
Public:: will present 'sales page' type experiences and purchase experiences must also work pre-login, after purchase users will need to login/create account by a one time password token (6 digit code) sent to their email/phone number

EX: ```Verify your email
Whop is a password-less platform. You will use this email to log in to your account. Please check tiggman+test1@gmail.com for your six digit code. Make sure to check spam 😉```

Once logged in we can then automatically populate email/user buyer info, open purchase modal and allow '1 click' buy for future purchases on the network.



## 🟡 Important Design Decisions

### 4. **LiveKit Room Architecture**
**Questions**:
- One room per Stream or reusable rooms per Space?
- How to handle room cleanup after stream ends?
- Token refresh strategy for long streams?
- Recording storage: S3, Mux, or both?

Answers: 
- Livestream tied to experience instead so one stream per experience potentially.  
- need to archive recording and list access to view it
- unsure 
- Cloudflare R2 (s3 like), Mux maybe?  


### 5. **Mux Hybrid Distribution**
**Questions**:
- When to switch from LiveKit-only to Mux distribution?
- Viewer count threshold for hybrid mode?
- How to handle stream migration mid-broadcast?
- Playback URL strategy (signed vs public)?

Answers:
- See MD project plans, determine based on number of potential calculated/expected viewers (we probably want to have experiences cache the expect based on the last stream that happened)... also if they're streaming to other remote locaitons like youtube we have to use Mux as well
- TBD


### 6. **Payment & Subscription Models**
**Questions**:
- Using Stripe Checkout or Elements?  -> Elements planned for now leave TODOs for full implementation
- How to handle free trials for Spaces? -> TBD placeholders for now w/ open issues
- Refund policy implementation? -> TBD placeholders for now w/ open issues
- Creator payout system needed? -> TBD placeholders for now w/ open issues
- Revenue split model? -> TBD placeholders for now w/ open issues

### 7. **Mobile-Specific Features**
**Questions**:
- Native video player or web player in Hotwire Native? -> TBD -> utilize perplexity to research
- Push notifications for stream starts? -> Yes required
- Offline content caching? -> TBD placeholders for now w/ open issues
- Native IAP or web payments only? -> TBD placeholders for now w/ open issues

## 🟢 Implementation Details Needed

### 8. **Button/Options Configuration**
**Issue**: Locale files for button options not clear
**Questions**:
- Where exactly in locale files do button options go? -> Perplexity research bullettrain.co docs
- Format for options with icons?
- How to add custom colors to buttons?

**Example needed**:
```yaml
# config/locales/en/spaces.en.yml
en:
  spaces:
    fields:
      status:
        options:
          draft: 
            label: "Draft"
            icon: "ti-pencil"
            color: "yellow"
          published:
            label: "Published"
            icon: "ti-check"
            color: "green"
```

### 9. **Testing Strategy**
**Questions**:
- Magic Test for all UI or just critical paths? -> critical only
- Unit tests with RSpec or Minitest? -> Minitest (see bullettrain recommended)
- API testing approach? -> TBD placeholders for now w/ open issues
- Load testing for streaming? -> TBD placeholders for now w/ open issues

### 10. **Background Jobs Structure**
**Questions**:
- Stream start/end job patterns?
- Clip generation job queues?
- Email notification jobs?
- Cleanup jobs for expired access?

Answer: Spec needs to be created by you

## 📊 Database & Performance

### 11. **Database Indexes**
**Questions**:
- Composite indexes for access pass lookups? -> Ideally
- Full-text search implementation (pg_search vs elasticsearch)? -> TBD placeholders for now w/ open issues
- Caching strategy (Redis keys structure)? -> Rails.cache.fetch / Russian doll caching


### 12. **File Storage**
**Questions**:
- Stream recordings: Active Storage or direct S3? -> R2
- Clip storage and CDN strategy? -> R2
- Image uploads for Spaces (Cloudinary vs S3)? -> R2 

## 🎥 Streaming Specifics

### 13. **Stream States & Transitions**
**Questions**:
- Pre-stream lobby implementation?  -> ideally a good UX
- Scheduled → Live transition automation?  -> Yes when live starts
- Grace period for reconnection? -> Yes research w/ perplexity
- Stream health monitoring? -> yes ideally

### 14. **Interactive Features**
**Questions**:
- Chat implementation (ActionCable vs LiveKit data channels)?  -> Getstream.io integration (perplexity research to compare vs liveKit)
- Reactions/emojis system? -> yes ideally
- Polls and Q&A features? -> utilizing something existing like livekit or getstream)
- Screen sharing permissions? -> yes needed, also ability to swap inputs/mic/etc

### 15. **Clip Generation**
**Questions**:
- Real-time clipping or post-stream only? -> post stream is fine
- AI-powered highlight detection? -> yes use superscaffolding to drop suggested ones and let the user confirm which they want for now
- Clip editing capabilities? -> TBD placeholders for now w/ open issues
- Social sharing from clips? -> Yes ideally

## 🚀 Deployment & DevOps

### 16. **Environment Setup**
**Questions**:
- Docker setup needed? 
- Required ENV variables list?
- Minimum server requirements?
- Auto-scaling triggers?

TBD placeholders for now w/ open issues -> Kamal2?  Somethign simple for now perplexity research for rails 8 best

### 17. **Monitoring**
**Questions**:
- APM tool preference (New Relic, DataDog)? -> Either 
- Error tracking (Sentry, Rollbar)? -> Sentry
- Stream quality metrics? -> TBD placeholders for now w/ open issues - perplexity research
- User analytics (Segment, Mixpanel)? -> Posthog probably


## 📱 Progressive Features

### 18. **Phase 2+ Features Priority**
**Questions** (for roadmap planning):
- Creator analytics dashboard?
- Affiliate program?
- Multi-streaming to external platforms?
- VOD library from recordings?
- Community features (Discord integration)?
- Virtual events/tickets?

TBD placeholders for now w/ open issues

## 🎨 UI/UX Decisions

### 19. **Theme Customization**
**Questions**:
- Creator custom branding level?
- White-label options?
- Custom domains for Spaces?
- Email template customization?

TBD placeholders for now w/ open issues

### 20. **Discovery & Search**
**Questions**:
- Category taxonomy for Experiences? -> yes AI suggest starting points
- Recommendation algorithm? -> TBD placeholders for now w/ open issues
- Featured/trending logic? -> TBD placeholders for now w/ open issues
- Search filters structure? -> TBD placeholders for now w/ open issues


---

## Recommended Next Steps

1. **Answer Critical Questions (1-3)** - These block core model creation
2. **Decide on LiveKit/Mux strategy (4-5)** - Affects streaming architecture  
3. **Clarify payment flow (6)** - Impacts AccessPass implementation
4. **Provide button options example (8)** - Needed for every model

## Quick Decision Framework

For each question above, please specify:
1. **Decision**: Your choice
2. **Rationale**: Why this approach
3. **Implementation Note**: Any special considerations

Example response format:
```markdown
### AccessPass Polymorphic Design
**Decision**: Hierarchical access - Space pass includes all Experiences
**Rationale**: Simpler UX, encourages higher-value purchases
**Implementation Note**: Add `includes_all_experiences` boolean to AccessPass
```

---

*This document should be updated with decisions as they're made, becoming the authoritative source for implementation details.*