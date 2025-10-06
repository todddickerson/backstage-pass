# 🎬 LiveKit Features Implementation Plan

**Based on:** Perplexity deep research (2025)  
**Date:** 2025-10-06  
**Status:** Research complete, ready to implement

---

## 🔍 **KEY FINDINGS FROM RESEARCH**

### **✅ ALREADY SUPPORTED IN OUR CONTROLS:**
1. **Camera Toggle** - setCameraEnabled API ✅
2. **Microphone Toggle** - setMicrophoneEnabled API ✅
3. **Screen Share** - setScreenShareEnabled API ✅
4. **Quality Presets** - VideoPresets (1080p/720p/480p) ✅
5. **Noise Suppression** - AudioCaptureOptions ✅
6. **Echo Cancellation** - AudioCaptureOptions ✅

### **🚀 AVAILABLE BUT NOT YET IMPLEMENTED:**
7. **Device Switching** - Dynamic camera/microphone selection
8. **Simulcast** - Multi-layer quality streaming
9. **Adaptive Streaming** - Auto quality adjustment
10. **Background Blur/Virtual Backgrounds** - Privacy features
11. **Recording Controls** - Egress service integration
12. **Participant Permissions** - Dynamic role management
13. **Advanced Audio** - Background voice cancellation (Krisp partnership)

---

## 📋 **IMPLEMENTATION PRIORITIES**

### **Phase 1: Core Broadcaster Experience (HIGH)**

#### **1. Device Switching** ⭐⭐⭐
**What:** Allow hosts to change camera/microphone mid-stream  
**How:** 
```javascript
// Get available devices
const devices = await navigator.mediaDevices.enumerateDevices();

// Switch camera
await localParticipant.switchActiveDevice('videoinput', deviceId);

// Switch microphone
await localParticipant.switchActiveDevice('audioinput', deviceId);
```

**UI:** Already built in broadcaster_controls.html.erb!
- Camera select dropdown ✅
- Microphone select dropdown ✅

**Implementation:** 
- Add Stimulus controller actions
- Populate device dropdowns
- Wire to LiveKit APIs

**Priority:** 🔴 CRITICAL (hosts need this!)

#### **2. Simulcast Configuration** ⭐⭐⭐
**What:** Publish multiple quality layers automatically  
**Benefits:**
- Viewers auto-get best quality for their bandwidth
- 17% overhead for publisher
- Smooth quality switching

**How:**
```javascript
// Enable simulcast in room options
const room = new Room({
  videoCaptureDefaults: {
    resolution: VideoPresets.h720.resolution,
  },
  publishDefaults: {
    simulcast: true,  // Enable simulcast!
    videoEncoding: {
      maxBitrate: 2_500_000,
      maxFramerate: 30,
    }
  }
});
```

**Priority:** 🔴 CRITICAL (major UX improvement)

#### **3. Quality Presets Integration** ⭐⭐
**What:** Let hosts choose broadcast quality  
**Options:**
- High: 1080p @ 30fps (4Mbps)
- Medium: 720p @ 30fps (2.5Mbps)
- Low: 480p @ 30fps (1.5Mbps)
- Mobile: 360p @ 15fps (800kbps)

**Already in UI:** Quality select dropdown ✅

**Implementation:**
```javascript
// Change quality
await localParticipant.setTrackPublishOptions(track, {
  videoEncoding: VideoPresets.h720
});
```

**Priority:** 🟡 HIGH

---

### **Phase 2: Advanced Features (MEDIUM)**

#### **4. Screen Share with Audio** ⭐⭐
**What:** Capture tab/window audio during screen share  
**Supported:** Chrome/Edge (navigator.mediaDevices.getDisplayMedia)

**Implementation:**
```javascript
await room.localParticipant.setScreenShareEnabled(true, {
  audio: true,  // Enable audio capture!
  video: true
});
```

**Priority:** 🟡 HIGH (for presentations)

#### **5. Recording Controls** ⭐⭐
**What:** Start/stop recording from UI  
**Service:** LiveKit Egress

**Implementation:**
```ruby
# Backend: Start recording
egress_service.start_room_composite_egress(
  room_name: stream.room_name,
  layout: "speaker-dark",
  file_output: {
    filepath: "recordings/#{stream.id}/#{Time.current.to_i}.mp4"
  }
)
```

**UI:** Add "Record" button to broadcaster controls

**Priority:** 🟢 MEDIUM

#### **6. Advanced Audio Processing** ⭐⭐
**What:** Krisp AI noise cancellation  
**Features:**
- Advanced noise suppression (better than browser default)
- Background voice cancellation
- Speech enhancement

**Requires:** Krisp partnership/API key

**Priority:** 🟢 MEDIUM (quality enhancement)

---

### **Phase 3: Premium Features (FUTURE)**

#### **7. Background Blur/Virtual Backgrounds** ⭐
**What:** Privacy/branding features  
**Implementation:** @livekit/track-processors package

**Priority:** 🔵 LOW

#### **8. Participant Management UI** ⭐
**What:** Host can mute participants, change roles  
**APIs:**
- remoteMuteTrack()
- updateParticipantMetadata()
- removeParticipant()

**Priority:** 🔵 LOW (future moderation)

---

## 🎯 **RECOMMENDED NEXT STEPS**

### **This Week (Top 3):**

#### **1. Device Switching Stimulus Controller (2-3 hours)** 🔴
**File:** `app/javascript/controllers/broadcaster_controls_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "cameraSelect", "micSelect", "cameraBtn", "micBtn", 
    "screenBtn", "cameraStatus", "micStatus", "screenStatus",
    "viewerCount", "duration", "bitrate", "fps", "resolution"
  ]
  
  connect() {
    console.log("Broadcaster controls connected!")
    this.initializeLiveKit()
    this.enumerateDevices()
  }
  
  async enumerateDevices() {
    const devices = await navigator.mediaDevices.enumerateDevices()
    
    // Populate camera dropdown
    const cameras = devices.filter(d => d.kind === 'videoinput')
    cameras.forEach(device => {
      const option = new Option(device.label || `Camera ${cameras.indexOf(device) + 1}`, device.deviceId)
      this.cameraSelectTarget.add(option)
    })
    
    // Populate microphone dropdown
    const mics = devices.filter(d => d.kind === 'audioinput')
    mics.forEach(device => {
      const option = new Option(device.label || `Microphone ${mics.indexOf(device) + 1}`, device.deviceId)
      this.micSelectTarget.add(option)
    })
  }
  
  async changeCamera(event) {
    const deviceId = event.target.value
    await this.room.localParticipant.switchActiveDevice('videoinput', deviceId)
    console.log("Camera switched to:", deviceId)
  }
  
  async changeMicrophone(event) {
    const deviceId = event.target.value
    await this.room.localParticipant.switchActiveDevice('audioinput', deviceId)
    console.log("Microphone switched to:", deviceId)
  }
  
  async toggleCamera() {
    const enabled = await this.room.localParticipant.setCameraEnabled(
      !this.room.localParticipant.isCameraEnabled
    )
    this.cameraStatusTarget.classList.toggle('hidden', !enabled)
  }
  
  async toggleMicrophone() {
    const enabled = await this.room.localParticipant.setMicrophoneEnabled(
      !this.room.localParticipant.isMicrophoneEnabled
    )
    this.micStatusTarget.classList.toggle('hidden', !enabled)
  }
  
  async toggleScreenShare() {
    const enabled = await this.room.localParticipant.setScreenShareEnabled(
      !this.room.localParticipant.isScreenShareEnabled,
      { audio: true }  // Enable tab audio!
    )
    this.screenStatusTarget.classList.toggle('hidden', !enabled)
  }
}
```

#### **2. Simulcast Enablement (1 hour)** 🔴
**File:** `app/javascript/controllers/stream_viewer_controller.js`

```javascript
const room = new Room({
  publishDefaults: {
    simulcast: true,  // Enable multi-layer streaming!
    videoSimulcastLayers: [
      VideoPresets.h720,   // High
      VideoPresets.h360,   // Medium
      VideoPresets.h180    // Low
    ]
  },
  videoCaptureDefaults: {
    resolution: VideoPresets.h720.resolution
  }
});
```

#### **3. Quality Selector for Viewers (1 hour)** 🟡
**Already in UI!** Just wire to LiveKit:

```javascript
async setQuality(event) {
  const quality = event.target.dataset.quality
  
  const videoTrack = this.room.remoteParticipants[0].getTrack(Track.Source.Camera)
  
  if (quality === 'auto') {
    videoTrack.setVideoQuality(VideoQuality.HIGH)  // Let LiveKit decide
  } else if (quality === 'high') {
    videoTrack.setVideoQuality(VideoQuality.HIGH)
  } else if (quality === 'medium') {
    videoTrack.setVideoQuality(VideoQuality.MEDIUM)  
  } else {
    videoTrack.setVideoQuality(VideoQuality.LOW)
  }
}
```

---

## 📊 **FEATURE COMPARISON**

| Feature | Status | Implementation | Priority |
|---------|--------|----------------|----------|
| Camera toggle | ✅ UI ready | Add controller | 🔴 CRITICAL |
| Mic toggle | ✅ UI ready | Add controller | 🔴 CRITICAL |
| Screen share | ✅ UI ready | Add controller | 🔴 CRITICAL |
| Device switching | ✅ UI ready | Add controller | 🔴 CRITICAL |
| Quality presets | ✅ UI ready | Add controller | 🟡 HIGH |
| Simulcast | ⚠️ Backend | Enable in config | 🔴 CRITICAL |
| Quality selector | ✅ UI ready | Add controller | 🟡 HIGH |
| Noise suppression | ✅ UI ready | Already enabled | ✅ DONE |
| Echo cancellation | ✅ UI ready | Already enabled | ✅ DONE |
| Volume control | ✅ UI ready | Add controller | 🟡 HIGH |
| Fullscreen | ✅ UI ready | Add controller | 🟡 HIGH |
| Recording | ⚠️ Backend | Egress integration | 🟢 MEDIUM |
| Background blur | ❌ Not started | Track processors | 🔵 LOW |

**UI is 90% ready! Just needs Stimulus controller!** 🎉

---

## 🎯 **RECOMMENDED IMPLEMENTATION ORDER**

### **Week 1 (Critical - 8 hours):**
1. **Stimulus broadcaster controller** (3h)
   - Device enumeration
   - Camera/mic toggle
   - Device switching
   - Screen share

2. **Simulcast enablement** (1h)
   - Enable in room config
   - Test quality layers

3. **Quality selector** (2h)
   - Wire viewer controls
   - Test switching

4. **Stats monitoring** (2h)
   - Bitrate display
   - FPS tracking
   - Connection quality

### **Week 2 (Polish - 6 hours):**
5. **Recording controls** (3h)
   - Start/stop recording
   - Egress integration
   
6. **Advanced audio** (2h)
   - Krisp integration (if available)
   - Enhanced processing

7. **Keyboard shortcuts** (1h)
   - C/M/S/F/?
   - Help overlay

---

## 💡 **KEY INSIGHTS FROM RESEARCH**

### **1. Simulcast is Essential** ⭐
- Only 17% more bandwidth for publisher
- Viewers get optimal quality automatically
- Smooth quality switching
- **Enables adaptive streaming**

### **2. Device Switching is Expected** ⭐
- Hosts need to change cameras mid-stream
- Microphone issues require quick switching
- No session interruption
- **Professional broadcaster requirement**

### **3. Quality Control is Important** ⭐
- Viewers on mobile/slow connections
- Bandwidth adaptation
- User preference
- **Better than buffering!**

### **4. Audio Quality Matters More** ⭐
- Poor audio = worse than poor video
- Echo/noise suppression critical
- Background cancellation for AI
- **Invest in audio first**

---

## 📝 **IMPLEMENTATION CHECKLIST**

### **Phase 1: Critical Features**
- [ ] Create broadcaster_controls_controller.js
- [ ] Implement device enumeration
- [ ] Wire camera toggle
- [ ] Wire microphone toggle
- [ ] Wire screen share
- [ ] Add device switching
- [ ] Enable simulcast
- [ ] Add quality selector
- [ ] Implement stats monitoring

### **Phase 2: Polish**
- [ ] Add recording controls
- [ ] Implement keyboard shortcuts
- [ ] Add advanced audio processing
- [ ] Test cross-browser
- [ ] Mobile optimization

### **Phase 3: Advanced**
- [ ] Background blur/virtual backgrounds
- [ ] Participant management UI
- [ ] AI features integration
- [ ] Analytics dashboard

---

## 🎨 **ENHANCED UI VISION**

**Broadcaster View (with all features):**
```
╔═════════════════════════════════════════════╗
║ Controls:                                   ║
║ [📹] [🎤] [🖥️] [📹↕️] [🎤↕️] [⚙️]          ║
║ Cam  Mic  Share Change  Switch Settings    ║
║                                             ║
║ Settings Panel:                             ║
║ 📹 Camera: [MacBook Pro Camera      ▼]    ║
║ 🎤 Microphone: [AirPods Pro         ▼]    ║
║ 🎚️ Quality: [● High (1080p)         ▼]    ║
║ ☑️ Noise Suppression (Enabled)             ║
║ ☑️ Echo Cancellation (Enabled)             ║
║ ☑️ Simulcast (3 layers)                    ║
║                                             ║
║ Stats:                                      ║
║ 📊 Bitrate: 2.5 Mbps | FPS: 30 | 1080p    ║
║ 📶 Connection: Excellent | Latency: 45ms   ║
╚═════════════════════════════════════════════╝
```

**Viewer View:**
```
╔═════════════════════════════════════════════╗
║ [🎚️ Auto ▼] [🔊 ━━━━━━ 100%] [📺]        ║
║ Quality       Volume            Fullscreen  ║
╚═════════════════════════════════════════════╝
```

---

## 🔧 **TECHNICAL NOTES**

### **From Research:**

**Simulcast Bandwidth:**
- Original: 1280x720 @ 2.5Mbps
- Medium: 640x360 @ 400kbps
- Low: 320x180 @ 125kbps
- **Total: ~3Mbps (+17% overhead)**

**Quality Presets (from LiveKit):**
- h1080: 1920x1080 @ 30fps (4Mbps)
- h720: 1280x720 @ 30fps (2.5Mbps)
- h540: 960x540 @ 30fps (1.7Mbps)
- h360: 640x360 @ 30fps (800kbps)
- h180: 320x180 @ 15fps (125kbps)

**Audio Settings:**
- Standard: 64kbps mono
- Hi-Fi: 510kbps stereo (music quality!)
- DTX: Reduces to 1kbps during silence

**Screen Share:**
- Resolution: Up to 1080p
- Framerate: 5-15fps (documents) or 30fps (video)
- Audio: Optional tab audio capture
- Multiple sources: Supported!

---

## 📚 **RESOURCES**

**APIs to Use:**
- `switchActiveDevice(kind, deviceId)` - Change input sources
- `setVideoQuality(quality)` - Viewer quality selection
- `enableSimulcast: true` - Multi-layer streaming
- `AudioCaptureOptions` - Echo/noise suppression
- `VideoPresets` - Quality tiers
- `start_room_composite_egress` - Recording

**Documentation:**
- LiveKit Docs: https://docs.livekit.io
- Device Management: https://docs.livekit.io/guides/room/device-management/
- Simulcast: https://docs.livekit.io/guides/room/adaptive-stream/
- Quality: https://docs.livekit.io/guides/room/video-quality/

---

## 🎯 **NEXT SESSION PLAN**

**Goal:** Implement Stimulus controller for broadcaster controls

**Tasks:**
1. Create `broadcaster_controls_controller.js` (1h)
2. Wire device enumeration (30min)
3. Implement toggle actions (1h)
4. Add device switching (1h)
5. Enable simulcast (30min)
6. Test complete flow (1h)

**Total:** ~5 hours for fully functional controls!

**Outcome:** Professional broadcaster experience with device management!

---

**Status:** Ready to implement! UI built, APIs researched, plan complete! 🚀
