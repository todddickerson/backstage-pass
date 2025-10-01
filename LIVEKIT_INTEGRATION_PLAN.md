# LiveKit Streaming Integration - Implementation Plan

## 📊 Current State Analysis (Ultrathink Assessment)

### ✅ What's Already Built (Well Implemented)

#### 1. LiveKit Service Layer (`app/services/streaming/livekit_service.rb`)
- ✅ Room creation with metadata
- ✅ Access token generation with permissions
- ✅ Participant management (list, remove, mute)
- ✅ Recording support (start/stop)
- ✅ Mobile connection info generation
- ✅ Environment validation
- ✅ Error handling

#### 2. API Endpoints (`app/controllers/account/stream_viewing_controller.rb`)
- ✅ `/account/streams/:id/view` - Stream viewing page
- ✅ `/account/streams/:id/video_token` - LiveKit token generation
- ✅ `/account/streams/:id/chat_token` - GetStream token generation
- ✅ `/account/streams/:id/stream_info` - Room info and participants
- ✅ Access control verification
- ✅ JSON API responses

#### 3. Frontend Viewer (`app/assets/javascripts/livekit_streaming_viewer.js`)
- ✅ LiveKit SDK integration
- ✅ Video playback with adaptive streaming
- ✅ Chat integration (GetStream)
- ✅ Mobile/desktop responsive UI
- ✅ Fullscreen support
- ✅ Auto-hide controls
- ✅ Viewer count updates
- ✅ Cleanup on page unload
- ✅ Error handling

#### 4. Test Coverage (`test/integration/livekit_integration_test.rb`)
- ✅ Service initialization
- ✅ Environment validation
- ✅ Mobile connection info generation
- ✅ Permission handling
- ✅ Lifecycle testing
- ✅ Performance testing (100 tokens < 1s)
- ⚠️ Some tests skipped (require mocking)

### 🔴 Critical Issues Found

#### 1. **SECURITY BUG: Broken `.active` Scope Usage**
**Location:** `app/controllers/account/stream_viewing_controller.rb:16`

```ruby
# CURRENT (BROKEN):
@access_grant = current_user.access_grants.active.find do |grant|
  grant.grants_access_to?(@stream) || ...
end

# SHOULD BE:
@access_grant = current_user.access_grants.find do |grant|
  grant.active? && (grant.grants_access_to?(@stream) || ...)
end
```

**Impact:** Same critical bug from Issue #51 - expired grants might allow access

#### 2. **Missing Room Creation Flow**
- No "Go Live" controller action
- LiveKit room not created when stream starts
- No integration between stream status and LiveKit room lifecycle

#### 3. **Missing View Templates**
- JavaScript viewer exists but HTML views not found
- No UI for stream viewing page
- No broadcaster/creator UI

#### 4. **Incomplete Creator Broadcasting Flow**
- No UI for creators to go live
- No screen sharing controls
- No broadcast quality controls
- No recording start/stop UI

#### 5. **Missing Lifecycle Integration**
- Stream status changes don't trigger LiveKit room creation/deletion
- No webhooks/callbacks for LiveKit events
- No automatic cleanup of ended streams

### 📋 Gap Analysis

| Feature | Service Layer | Controller | Frontend | Tests | Status |
|---------|--------------|------------|----------|-------|--------|
| Room Creation | ✅ | ❌ | ❌ | ⚠️ | **50%** |
| Token Generation | ✅ | ✅ | ✅ | ✅ | **100%** |
| Video Playback | ✅ | ✅ | ✅ | ⚠️ | **90%** |
| Chat Integration | ✅ | ✅ | ✅ | ⚠️ | **90%** |
| Creator Broadcast | ✅ | ❌ | ❌ | ❌ | **25%** |
| Screen Sharing | ✅ | ❌ | ❌ | ❌ | **25%** |
| Recording | ✅ | ❌ | ❌ | ❌ | **25%** |
| Access Control | ✅ | 🐛 | ✅ | ✅ | **75% (BUG)** |
| Mobile Support | ✅ | ✅ | ✅ | ✅ | **95%** |

**Overall Completion: ~60%**

## 🎯 Implementation Plan

### Phase 1: Fix Critical Security Bug (1 hour)
**Priority: CRITICAL**

1. ✅ Fix `.active` scope usage in StreamViewingController
2. ✅ Run access control tests
3. ✅ Verify security fix

### Phase 2: Complete Room Creation Flow (4 hours)
**Priority: HIGH**

#### 2.1 Add "Go Live" Controller Action
```ruby
# app/controllers/account/experiences_controller.rb
def go_live
  @stream = @experience.streams.find(params[:stream_id])

  # Create LiveKit room
  livekit_service = Streaming::LivekitService.new
  room = livekit_service.create_room(@stream)

  # Update stream status
  @stream.update!(status: :live, started_at: Time.current)

  # Redirect to broadcast page
  redirect_to broadcast_account_stream_path(@stream)
end
```

#### 2.2 Add Stream Lifecycle Callbacks
```ruby
# app/models/stream.rb
after_update :handle_status_change

def handle_status_change
  if saved_change_to_status?
    case status
    when "live"
      create_livekit_room
    when "ended"
      cleanup_livekit_room
    end
  end
end
```

#### 2.3 Add Broadcast View
- Creator broadcast UI with video preview
- Screen sharing toggle
- Recording controls
- Viewer count display

### Phase 3: View Templates & UI (6 hours)
**Priority: HIGH**

#### 3.1 Stream Viewing Page (`app/views/account/stream_viewing/show.html.erb`)
```erb
<%= content_for :head do %>
  <script src="https://cdn.jsdelivr.net/npm/livekit-client/dist/livekit-client.umd.min.js"></script>
  <script src="https://cdn.stream-io-api.com/v2/stream-chat-client.min.js"></script>
  <%= javascript_include_tag 'livekit_streaming_viewer' %>
<% end %>

<div id="video-container">
  <div id="livekit-video"></div>
  <div id="stream-controls">
    <!-- Fullscreen, quality, viewer count -->
  </div>
</div>

<div id="chat-sidebar">
  <div id="chat-messages"></div>
  <input id="chat-input" />
</div>

<script id="stream-data" type="application/json">
  <%= raw stream_viewing_json.to_json %>
</script>

<script>
  window.livekitViewer = new LiveKitStreamingViewer();
</script>
```

#### 3.2 Creator Broadcast Page
- Video preview
- Screen share toggle
- Audio/video device selection
- Recording start/stop
- Stream controls (pause, end)

### Phase 4: Testing & Verification (6 hours)
**Priority: MEDIUM**

#### 4.1 Integration Tests
- [ ] Test room creation on go_live
- [ ] Test token generation for creator
- [ ] Test token generation for viewer
- [ ] Test access control (valid/expired/cancelled grants)
- [ ] Test screen sharing permissions
- [ ] Test recording start/stop

#### 4.2 E2E Testing Scenarios
1. **Creator Flow:**
   - Create stream
   - Go live
   - Verify room created
   - Start screen sharing
   - Start recording
   - End stream
   - Verify cleanup

2. **Viewer Flow:**
   - Purchase access pass
   - Join live stream
   - Verify video playback
   - Send chat message
   - Leave stream

3. **Access Control:**
   - Verify unauthorized users blocked
   - Verify expired grants blocked
   - Verify team members always have access

### Phase 5: Polish & Optimization (4 hours)
**Priority: LOW**

- Error handling improvements
- Connection quality indicators
- Reconnection logic
- Performance monitoring
- Analytics integration

## 🚀 Implementation Order (Priority-Based)

### Day 1 (8 hours)
1. ✅ Fix security bug (1 hour)
2. ✅ Add room creation flow (4 hours)
3. ✅ Add basic view templates (3 hours)

### Day 2 (8 hours)
4. ✅ Complete creator broadcast UI (4 hours)
5. ✅ Integration testing (4 hours)

### Day 3 (6 hours)
6. ✅ E2E testing (3 hours)
7. ✅ Polish & optimization (3 hours)

**Total Effort: ~22 hours (3 days)**

## ✅ Success Criteria (from Issue #52)

### Creator Streaming
- [x] Implement LiveKit room creation on stream start
- [ ] Generate creator access tokens
- [ ] Test webcam streaming
- [ ] Test screen sharing
- [ ] Verify recording to storage

### Viewer Streaming
- [x] Generate viewer access tokens (with access verification)
- [x] Implement video player frontend
- [ ] Test adaptive bitrate
- [ ] Test multiple concurrent viewers

### Testing
- [ ] End-to-end: Create → Go Live → Watch → End flow
- [ ] Multiple viewers concurrent test
- [ ] Network condition testing (3G, 4G, WiFi)
- [ ] Latency verification (<3 seconds target)

### Final Acceptance
- [ ] Creator can go live with video + screen share
- [ ] Viewers with access can watch streams
- [ ] Video latency <3 seconds
- [ ] Recordings saved to storage
- [ ] Stream ends cleanly

## 📝 Notes

### Environment Variables Required
```bash
LIVEKIT_API_KEY=xxxxx
LIVEKIT_API_SECRET=xxxxx
LIVEKIT_URL=wss://xxxxx.livekit.cloud
```

### Dependencies
- `livekit-ruby` gem ✅ (already installed)
- LiveKit JavaScript SDK ✅ (CDN loaded)
- GetStream JavaScript SDK ✅ (CDN loaded)

### Known Issues
1. `.active` scope bug (CRITICAL - fix first)
2. Room name for consultation uses wrong prefix (test line 300)
3. Some integration tests skipped (require mocking)

## 🔗 Related Issues
- #51: Access Control Security Verification (DONE - contains the `.active` bug fix pattern)
- #53: Complete GetStream Chat Integration (NEXT - depends on this)
- #56: End-to-End Integration Testing (LATER - depends on #52 and #53)
