# Namespacing Conventions (Andrew Culver Best Practices)

## 🔴 CRITICAL: Follow These Rules Strictly

Based on Andrew Culver's Rails namespacing best practices (Bullet Train creator), we follow these strict conventions:

## Core Principles

### 1. Primary Subject Rule
**Never namespace the main subject of a domain**

```ruby
# ✅ CORRECT
Space                    # Primary marketplace unit
Experience               # Primary content unit
AccessPass               # Primary payment/access mechanism
Stream                   # Primary streaming content

# ❌ WRONG
Teams::Space            # Never namespace under Team
Spaces::Experience      # Never namespace under Space
AccessPasses::AccessPass # Never self-namespace
```

### 2. Drop Namespace References Within Context

```ruby
# In Creators::ProfilesController
@profile = current_user.creator_profile  # NOT @creators_profile

# In AccessPasses::WaitlistEntriesController  
@entry = @access_pass.waitlist_entries.find(params[:id])  # NOT @access_passes_waitlist_entries

# In model associations within namespace
class AccessPasses::WaitlistEntry < ApplicationRecord
  belongs_to :access_pass  # NOT belongs_to :access_passes_access_pass
  belongs_to :user         # Rails auto-resolves correctly
end
```

### 3. Bridge Model Namespacing

```ruby
# Global-to-Global bridges
AccessPassExperience     # AccessPass ↔ Experience (both global)
SpaceMembership         # Space ↔ User (both global)

# Never do this
AccessPasses::Experience # ❌ Implies Experience is namespaced
Experiences::AccessPass  # ❌ Implies AccessPass is namespaced
```

## Our Model Structure

### Primary Subjects (Global)
These are the main concepts of our marketplace - NEVER namespace these:

```ruby
# Core Marketplace Models
class Space < ApplicationRecord
  belongs_to :team
  has_many :experiences
  has_many :access_passes
end

class Experience < ApplicationRecord
  belongs_to :space
  has_many :streams
end

class AccessPass < ApplicationRecord
  belongs_to :space
  has_many :access_pass_experiences
  has_many :experiences, through: :access_pass_experiences
end

class Stream < ApplicationRecord
  belongs_to :experience
  belongs_to :host, class_name: 'User'
end
```

### Supporting Models (Namespaced)
These provide additional functionality to primary subjects:

```ruby
# Creator domain
module Creators
  class Profile < ApplicationRecord
    self.table_name = "creators_profiles"
    belongs_to :user
    # Supporting creator identity features
  end
end

# Access control domain
module AccessPasses
  class WaitlistEntry < ApplicationRecord
    self.table_name = "access_passes_waitlist_entries"
    belongs_to :access_pass
    belongs_to :user
    # Waitlist approval workflow
  end
end

# Billing domain
module Billing
  class Purchase < ApplicationRecord
    self.table_name = "billing_purchases"
    belongs_to :access_pass
    belongs_to :user
    # Payment processing details
  end
end

# Streaming domain (supporting features)
module Streaming
  class Recording < ApplicationRecord
    self.table_name = "streaming_recordings"
    belongs_to :stream
    # Recording storage and processing
  end
  
  class Clip < ApplicationRecord
    self.table_name = "streaming_clips"
    belongs_to :stream
    # Highlight clips from streams
  end
end
```

### Bridge Models (Global)
Connect two global models:

```ruby
class AccessPassExperience < ApplicationRecord
  belongs_to :access_pass
  belongs_to :experience
end

class SpaceMembership < ApplicationRecord
  belongs_to :space
  belongs_to :user
  # Role: owner, moderator, etc.
end

class StreamParticipant < ApplicationRecord
  belongs_to :stream
  belongs_to :user
  # Participant role and permissions
end
```

## Migration Patterns

When creating namespaced models, specify foreign keys explicitly:

```ruby
class CreateAccessPassesWaitlistEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :access_passes_waitlist_entries do |t|
      t.references :access_pass, foreign_key: true
      t.references :user, foreign_key: true
      t.jsonb :answers
      t.string :status
      t.timestamps
    end
  end
end
```

## Controller Structure

```ruby
# app/controllers/
├── account/
│   ├── spaces_controller.rb                    # Primary subject
│   ├── experiences_controller.rb               # Primary subject
│   ├── access_passes_controller.rb             # Primary subject
│   ├── streams_controller.rb                   # Primary subject
│   ├── creators/
│   │   └── profiles_controller.rb              # Namespaced supporting
│   ├── access_passes/
│   │   └── waitlist_entries_controller.rb      # Namespaced supporting
│   └── billing/
│       └── purchases_controller.rb             # Namespaced supporting
└── public/
    ├── spaces_controller.rb                    # Public views
    └── creators/
        └── profiles_controller.rb              # @username routes
```

## Super Scaffolding Commands

```bash
# Primary subjects - NO namespace
rails generate super_scaffold Space Team name:text_field
rails generate super_scaffold Experience Space name:text_field
rails generate super_scaffold AccessPass Space name:text_field
rails generate super_scaffold Stream Experience title:text_field

# Supporting models - WITH namespace
rails generate super_scaffold Creators::Profile User username:text_field
rails generate super_scaffold AccessPasses::WaitlistEntry AccessPass,User status:options
rails generate super_scaffold Billing::Purchase AccessPass,User amount:number_field

# Bridge models - NO namespace (global-to-global)
rails generate super_scaffold AccessPassExperience AccessPass,Experience included:boolean
```

## Why This Matters

1. **Future-proof**: Can expand domains without refactoring
2. **Rails conventions**: Works with autoloading and associations
3. **Clean code**: `@profile` instead of `@creators_profile` in controllers
4. **Natural reading**: `space.experiences` not `space.spaces_experiences`
5. **Bullet Train alignment**: Follows framework creator's proven patterns

## Anti-Patterns to Avoid

```ruby
# ❌ NEVER DO THESE:
Teams::Space                    # Space is primary subject
Spaces::Space                   # Self-namespacing
@teams_space                    # In Teams context
@access_passes_waitlist_entry   # In AccessPasses context
subscription.subscriptions_plan # Redundant namespace in association
```

## Decision Rationale

- **Space, Experience, AccessPass, Stream**: Core marketplace concepts → Global
- **CreatorProfile → Creators::Profile**: Supporting user feature → Namespaced
- **Purchase → Billing::Purchase**: Payment implementation detail → Namespaced
- **WaitlistEntry → AccessPasses::WaitlistEntry**: Access control feature → Namespaced
- **Recording, Clip → Streaming::{Recording,Clip}**: Stream supporting features → Namespaced

This structure ensures clean domain boundaries while maintaining flexibility for future expansion.