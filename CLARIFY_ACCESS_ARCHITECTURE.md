# Access Pass vs Access Grant Architecture Clarification

## Core Concepts

### AccessPass (Product Definition)
- **What it is**: A sellable product/tier that creators define
- **Belongs to**: Space
- **Examples**: "VIP Access", "Monthly Membership", "Lifetime Pass"
- **Contains**: Name, description, pricing, stock limits, included experiences
- **URL**: `/space-slug/access-pass-slug` (sales page)

### AccessGrant (Purchase Record)  
- **What it is**: A user's purchased/granted access to a space or experience
- **Belongs to**: User, Team, and Purchasable (polymorphic - Space or Experience)
- **Examples**: "John bought VIP Access on 2025-01-15"
- **Contains**: User reference, purchase date, expiration, status
- **Purpose**: Tracks who has access to what

## Relationships

```ruby
# Product Hierarchy
Team
  has_many :spaces
  has_many :access_grants  # All purchases across their spaces
  
Space  
  belongs_to :team
  has_many :access_passes  # Products for sale
  has_many :access_grants, as: :purchasable  # Direct space purchases
  has_many :experiences
  
AccessPass  # PRODUCT DEFINITION
  belongs_to :space
  has_many :access_pass_experiences  # What's included
  has_many :experiences, through: :access_pass_experiences
  has_many :access_grants  # Who bought this product
  
Experience
  belongs_to :space  
  has_many :access_grants, as: :purchasable  # Direct experience purchases
  
# Purchase/Grant Records
User
  has_many :access_grants  # Everything they've purchased
  
AccessGrant  # PURCHASE RECORD
  belongs_to :user  # Who has access
  belongs_to :team  # For analytics/admin
  belongs_to :purchasable, polymorphic: true  # What they bought (Space or Experience)
  belongs_to :access_pass, optional: true  # Which product they bought (if applicable)
```

## Flow Example

1. Creator creates a Space: "Tech Talks Pro"
2. Creator defines AccessPass products:
   - "Basic Pass" - $10/month, includes recorded content
   - "VIP Pass" - $50/month, includes live streams + recordings
3. User visits `/tech-talks-pro/vip-pass` (AccessPass sales page)
4. User purchases the VIP Pass
5. System creates AccessGrant:
   - user: buyer
   - team: creator's team (for analytics)
   - purchasable: Space (or specific Experience)
   - access_pass: VIP Pass (reference to product bought)
   - status: active
   - expires_at: 30 days from now

## Current Issues to Fix

### 1. Missing AccessPass reference in AccessGrant
The AccessGrant should reference which AccessPass product was purchased:

```ruby
class AccessGrant < ApplicationRecord
  belongs_to :access_pass, optional: true  # Which product definition
  belongs_to :purchasable, polymorphic: true  # What access it grants to
end
```

### 2. Team relationships need both
```ruby
class Team < ApplicationRecord
  has_many :spaces
  has_many :access_grants  # All purchases/grants
  # Access passes are accessed through spaces
  has_many :access_passes, through: :spaces
end
```

### 3. AccessPass needs grants relationship
```ruby
class AccessPass < ApplicationRecord
  belongs_to :space
  has_many :access_grants  # Track who bought this product
  has_many :purchasers, through: :access_grants, source: :user
end
```

## Migration Strategy

1. ✅ Renamed access_passes table to access_grants
2. ✅ Created new access_passes table for product definitions
3. ⚠️ Need to add access_pass_id to access_grants table
4. ⚠️ Need to create access_pass_experiences join table
5. ⚠️ Need to update all relationships properly

## Naming Rationale

- **AccessPass**: What you buy (like a concert ticket type)
- **AccessGrant**: What you own (your actual ticket with seat number)

This separation allows:
- Multiple pricing tiers (different AccessPass products)
- Tracking who bought what (AccessGrant records)
- Complex inclusion rules (AccessPassExperience join table)
- Direct purchases (bypass AccessPass, create AccessGrant directly)
- Comped access (create AccessGrant without payment)