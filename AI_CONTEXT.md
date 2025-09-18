# Current Task Context

## 🎯 Working on Issue #46

### Title: [STORY 8] Live Stream Viewing - Complete Viewer Experience

### Description:
## Overview

Complete the viewer side of live streaming functionality. Backend LiveKit integration exists but viewer interface and access control need implementation.

## User Story

**As a** viewer with access  
**I want to** watch live streams  
**So that** I can consume the content I paid for

## Acceptance Criteria

### Core Viewing Experience
- [ ] Can see upcoming and live streams in purchased Spaces
- [ ] Can join live stream with one click  
- [ ] Video plays smoothly with adaptive quality
- [ ] Can participate in chat
- [ ] Can use reactions/emojis
- [ ] Can full-screen the video
- [ ] Mobile-responsive video player

### Access Control
- [ ] Only users with valid Access Pass can view
- [ ] Proper error messages for unauthorized access
- [ ] Seamless authentication check before stream access
- [ ] Grace period for recently expired passes

### Stream Discovery  
- [ ] Dashboard showing "My Streams" for purchased access passes
- [ ] Upcoming stream notifications
- [ ] Live stream indicators
- [ ] Recently ended stream recordings (if available)

## Technical Implementation

### Models (Already Implemented)
✅ Stream model with LiveKit integration exists
✅ Access control methods available  
✅ Stream status tracking (scheduled, live, ended)

### Controllers Needed
```ruby
# app/controllers/account/purchased_spaces_controller.rb
class Account::PurchasedSpacesController < Account::ApplicationController
  # Show user's purchased spaces and upcoming streams
end

# app/controllers/account/stream_viewing_controller.rb  
class Account::StreamViewingController < Account::ApplicationController
  # Handle stream viewing with access control
  
  def show
    # Verify user has access to stream
    # Generate LiveKit viewer token
    # Render streaming interface
  end
  
  def video_token
    # Generate LiveKit token for authenticated viewer
  end
  
  def chat_token  
    # Generate GetStream chat token
  end
end
```

### Views Needed
```
app/views/account/purchased_spaces/
├── index.html.erb          # Dashboard of purchased content
└── _stream_card.html.erb   # Stream preview cards

app/views/account/stream_viewing/
├── show.html.erb           # Main streaming page
├── _video_player.html.erb  # LiveKit video component  
└── _chat_panel.html.erb    # GetStream chat component
```

### Frontend Components
- [ ] LiveKit video player integration
- [ ] GetStream chat widget
- [ ] Responsive video controls
- [ ] Full-screen functionality
- [ ] Mobile touch controls

### Routes Integration
```ruby
# config/routes.rb additions
namespace :account do
  resources :purchased_spaces, only: [:index]
  
  resources :streams, only: [:show], controller: 'stream_viewing' do
    member do
      get :video_token
      get :chat_token
    end
  end
end
```

## Access Control Logic

### Purchase Verification
```ruby
def verify_stream_access
  @stream = Stream.find(params[:id])
  @access_pass = @stream.experience.access_passes.find do |pass|
    current_user.has_active_access?(pass)
  end
  
  unless @access_pass
    redirect_to public_space_path(@stream.experience.space.slug), 
                alert: "Access required to view this stream"
  end
end
```

### Token Generation
```ruby
def generate_viewer_token
  LiveKit::AccessToken.new(
    api_key: Rails.application.credentials.livekit.api_key,
    api_secret: Rails.application.credentials.livekit.api_secret
  ).tap do |token|
    token.identity = current_user.id.to_s
    token.name = current_user.name
    token.add_grant(LiveKit::VideoGrant.new(
      room_join: true,
      room: @stream.room_name
    ))
  end.to_jwt
end
```

## Integration Points

### LiveKit Integration
- [ ] Viewer token generation with proper permissions
- [ ] Room joining with participant limits
- [ ] Video quality adaptation
- [ ] Connection health monitoring

### GetStream Chat
- [ ] Viewer chat authentication
- [ ] Real-time message sync
- [ ] Chat moderation (viewer restrictions)  
- [ ] Emoji reactions integration

### Purchase System Integration
- [ ] Verify active access passes
- [ ] Handle subscription status
- [ ] Grace period for expired access
- [ ] Redirect to purchase if no access

## Testing Requirements

### System Tests
```ruby
# test/system/stream_viewing_test.rb
test "viewer with access can join stream"
test "viewer without access is redirected to purchase"
test "chat functionality works for authenticated viewers"
test "video player loads and displays stream"
test "full-screen mode works"
```

### Integration Tests
```ruby
# test/controllers/account/stream_viewing_controller_test.rb
test "generates valid LiveKit token for authorized user"
test "denies access for unauthorized user"
test "handles expired access passes appropriately"
```

## Dependencies

### Hard Dependencies
- ✅ LiveKit configuration (already exists)
- ✅ GetStream configuration (already exists)
- ✅ Stream model (already exists)
- ❌ **Working payment processing** (Issue #45 - Critical)

### Soft Dependencies  
- User authentication system (✅ working)
- Access pass purchase system (❌ needs fixing)
- Email notification system (✅ working)

## Mobile Considerations

### Responsive Design
- [ ] Mobile video player optimization
- [ ] Touch-friendly controls
- [ ] Portrait/landscape orientation handling
- [ ] Chat overlay for small screens

### Performance
- [ ] Adaptive bitrate streaming
- [ ] Connection quality indicators  
- [ ] Graceful degradation for poor connections
- [ ] Battery usage optimization

## Success Metrics

### Technical Metrics
- Video load time < 3 seconds
- Chat message latency < 500ms
- Stream uptime > 99%
- Mobile compatibility across devices

### User Experience
- Single-click stream joining
- Intuitive video controls
- Reliable chat functionality
- Clear access messaging

## Estimated Effort

**3-4 days** including testing and mobile optimization

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Comprehensive test coverage
- [ ] Mobile responsive design
- [ ] Code reviewed and merged
- [ ] Integration with purchase system working
- [ ] Documentation updated

## Next Steps After Completion

1. Live Stream Hosting improvements (creator side)
2. Recording playback functionality  
3. Stream analytics and metrics
4. Advanced chat features (reactions, moderation)

## Related Issues

- Depends on: #45 (Payment Processing)
- Enables: Creator hosting improvements
- Prepares: Mobile app streaming foundation

### Branch: issue-46

## 📋 Implementation Checklist:
- [ ] Review issue requirements above
- [ ] Check NAMESPACING_CONVENTIONS.md before creating models
- [ ] Run validation: `ruby .claude/validate-namespacing.rb "command"`
- [ ] Use super_scaffold for all new models
- [ ] Follow PUBLIC_ROUTES_ARCHITECTURE.md for routes
- [ ] Maintain team context where needed
- [ ] Write tests (Magic Test for UI, RSpec for models)
- [ ] Update documentation if needed

## 🔧 Common Commands:
```bash
# Validate namespacing
ruby .claude/validate-namespacing.rb "rails generate super_scaffold ModelName"

# Generate model
rails generate super_scaffold ModelName ParentModel field:type

# Run tests
rails test
rails test:system

# Check changes
git status
git diff

# When complete
bin/gh-complete 46 "PR title describing changes"
```

## 📚 Key Documentation:
- CLAUDE.md - Project instructions (MUST READ)
- NAMESPACING_CONVENTIONS.md - Model naming rules
- TEAM_SPACE_ARCHITECTURE.md - Team/Space relationship
- PUBLIC_ROUTES_ARCHITECTURE.md - Route structure
- AUTHENTICATION_PASSWORDLESS.md - Auth implementation

## 🚨 Important Notes:
- Public routes do NOT need team context
- Primary subjects (Space, Experience, AccessPass, Stream) should NOT be namespaced
- Supporting models should be namespaced (Creators::Profile, Billing::Purchase)
- Always validate namespacing before generating models

---
*Context generated at: Thu Sep 18 16:00:45 EDT 2025*
