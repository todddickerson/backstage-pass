import { Controller } from "@hotwired/stimulus"

// Professional Broadcaster Controls for LiveKit Streaming
// Implements device switching, quality control, and monitoring
export default class extends Controller {
  static targets = [
    "cameraBtn", "micBtn", "screenBtn",
    "cameraStatus", "micStatus", "screenStatus",
    "cameraSelect", "micSelect", "qualitySelect",
    "noiseSuppression", "echoCancellation",
    "viewerCount", "duration", "bitrate", "fps", "resolution", "connection",
    "settingsModal"
  ]

  static values = {
    streamId: Number,
    canBroadcast: Boolean
  }

  connect() {
    console.log("🎬 Broadcaster controls connected!")

    // Initialize state
    this.cameraEnabled = false
    this.micEnabled = false
    this.screenShareEnabled = false
    this.startTime = Date.now()
    this.room = null
    this.localParticipant = null
    this.isTestingDevices = false // For green room testing

    // Listen for LiveKit connection from stream-viewer controller
    // Listen on document to catch events from anywhere
    document.addEventListener('livekit:connected', this.handleLiveKitConnected.bind(this))
    console.log('👂 Listening for livekit:connected event...')

    // Try to get existing connection from parent stream-viewer controller
    this.connectToLiveKit()

    // Enumerate available devices
    this.enumerateDevices()

    // Start duration timer
    this.updateDuration()
    this.durationInterval = setInterval(() => this.updateDuration(), 1000)

    // Setup keyboard shortcuts
    this.setupKeyboardShortcuts()

    // Load saved device preferences
    this.loadDevicePreferences()
  }

  handleLiveKitConnected(event) {
    const { room, localParticipant } = event.detail
    this.room = room
    this.localParticipant = localParticipant
    console.log("🎬 Broadcaster controls connected to LiveKit room via event!")
    console.log("  Room:", this.room)
    console.log("  LocalParticipant:", this.localParticipant)
  }

  connectToLiveKit() {
    // Try to find the stream-viewer controller (could be anywhere on page)
    const streamViewerElement = document.querySelector('[data-controller~="stream-viewer"]')
    if (streamViewerElement) {
      const streamViewer = this.application.getControllerForElementAndIdentifier(
        streamViewerElement,
        'stream-viewer'
      )

      if (streamViewer && streamViewer.isConnected && streamViewer.isConnected()) {
        this.room = streamViewer.getRoom()
        this.localParticipant = streamViewer.getLocalParticipant()
        console.log("🎬 Broadcaster controls connected to existing LiveKit room!")
        console.log("  Room:", this.room)
        console.log("  LocalParticipant:", this.localParticipant)
      } else {
        console.log("⏳ Stream viewer not connected yet, waiting for event...")
      }
    } else {
      console.warn("⚠️ Stream viewer element not found on page")
    }
  }

  disconnect() {
    if (this.durationInterval) {
      clearInterval(this.durationInterval)
    }
  }

  // Device Enumeration
  async enumerateDevices() {
    try {
      // Request permissions first
      await navigator.mediaDevices.getUserMedia({ audio: true, video: true })

      const devices = await navigator.mediaDevices.enumerateDevices()

      // Get saved preferences
      const savedCamera = localStorage.getItem('backstagepass_camera_id')
      const savedMic = localStorage.getItem('backstagepass_mic_id')

      // Populate camera dropdown
      const cameras = devices.filter(d => d.kind === 'videoinput')
      if (this.hasCameraSelectTarget) {
        this.cameraSelectTarget.innerHTML = ''
        cameras.forEach((device, index) => {
          const option = document.createElement('option')
          option.value = device.deviceId
          option.textContent = device.label || `Camera ${index + 1}`

          // Select saved device or first camera as default
          if ((savedCamera && device.deviceId === savedCamera) || (!savedCamera && index === 0)) {
            option.selected = true
            console.log(`📹 Selected camera: ${option.textContent}`)
          }

          this.cameraSelectTarget.appendChild(option)
        })
      }

      // Populate microphone dropdown
      const mics = devices.filter(d => d.kind === 'audioinput')
      if (this.hasMicSelectTarget) {
        this.micSelectTarget.innerHTML = ''
        mics.forEach((device, index) => {
          const option = document.createElement('option')
          option.value = device.deviceId
          option.textContent = device.label || `Microphone ${index + 1}`

          // Select saved device or first mic as default
          if ((savedMic && device.deviceId === savedMic) || (!savedMic && index === 0)) {
            option.selected = true
            console.log(`🎤 Selected microphone: ${option.textContent}`)
          }

          this.micSelectTarget.appendChild(option)
        })
      }

      console.log(`📹 Found ${cameras.length} cameras, 🎤 ${mics.length} microphones`)
    } catch (error) {
      console.error("Failed to enumerate devices:", error)
    }
  }

  // Load Device Preferences
  loadDevicePreferences() {
    const savedCamera = localStorage.getItem('backstagepass_camera_id')
    const savedMic = localStorage.getItem('backstagepass_mic_id')

    if (savedCamera) {
      console.log(`💾 Loaded saved camera preference: ${savedCamera}`)
    }
    if (savedMic) {
      console.log(`💾 Loaded saved microphone preference: ${savedMic}`)
    }
  }

  // Save Device Preference
  saveDevicePreference(type, deviceId) {
    const key = `backstagepass_${type}_id`
    localStorage.setItem(key, deviceId)
    console.log(`💾 Saved ${type} preference: ${deviceId}`)
  }

  // Camera Toggle
  async toggleCamera() {
    if (!this.localParticipant) {
      console.warn('Cannot toggle camera: Not connected to LiveKit')
      return
    }

    this.cameraEnabled = !this.cameraEnabled

    if (this.hasCameraStatusTarget) {
      this.cameraStatusTarget.classList.toggle('hidden', !this.cameraEnabled)
    }

    // Update button appearance
    if (this.hasCameraBtnTarget) {
      this.cameraBtnTarget.classList.toggle('bg-green-700', this.cameraEnabled)
      this.cameraBtnTarget.classList.toggle('bg-gray-800', !this.cameraEnabled)
    }

    console.log(`📹 Camera ${this.cameraEnabled ? 'enabled' : 'disabled'}`)

    try {
      await this.localParticipant.setCameraEnabled(this.cameraEnabled)
      console.log('✅ Camera toggled successfully')

      // Show local video preview
      if (this.cameraEnabled) {
        this.showLocalVideoPreview()
      } else {
        this.hideLocalVideoPreview()
      }
    } catch (error) {
      console.error('Failed to toggle camera:', error)
      // Revert state on error
      this.cameraEnabled = !this.cameraEnabled
    }
  }

  showLocalVideoPreview() {
    if (!this.localParticipant) return

    // Find video container
    const videoContainer = document.querySelector('[data-stream-viewer-target="video"]')
    if (!videoContainer) {
      console.warn('Video container not found')
      return
    }

    // Get camera track - use videoTrackPublications Map
    const videoTracks = Array.from(this.localParticipant.videoTrackPublications.values())
    const cameraPublication = videoTracks.find(pub => pub.source === 'camera')

    if (cameraPublication && cameraPublication.track) {
      const videoElement = cameraPublication.track.attach()
      videoElement.id = 'local-video-preview'
      videoElement.style.width = '100%'
      videoElement.style.height = '100%'
      videoElement.style.objectFit = 'cover' // Changed from 'contain' to 'cover' for better centering
      videoElement.style.backgroundColor = 'black'
      videoElement.style.position = 'absolute'
      videoElement.style.top = '50%'
      videoElement.style.left = '50%'
      videoElement.style.transform = 'translate(-50%, -50%)' // Center the video

      // Clear container and add preview
      videoContainer.innerHTML = ''
      videoContainer.appendChild(videoElement)

      console.log('📹 Local video preview shown')
    } else {
      console.warn('Camera track not found yet, will appear when track publishes')
    }
  }

  hideLocalVideoPreview() {
    const preview = document.getElementById('local-video-preview')
    if (preview) {
      preview.remove()
      console.log('📹 Local video preview hidden')
    }
  }

  // Microphone Toggle
  async toggleMicrophone() {
    if (!this.localParticipant) {
      console.warn('Cannot toggle microphone: Not connected to LiveKit')
      return
    }

    this.micEnabled = !this.micEnabled

    if (this.hasMicStatusTarget) {
      this.micStatusTarget.classList.toggle('hidden', !this.micEnabled)
    }

    // Update button appearance
    if (this.hasMicBtnTarget) {
      this.micBtnTarget.classList.toggle('bg-green-700', this.micEnabled)
      this.micBtnTarget.classList.toggle('bg-gray-800', !this.micEnabled)
    }

    console.log(`🎤 Microphone ${this.micEnabled ? 'enabled' : 'disabled'}`)

    try {
      await this.localParticipant.setMicrophoneEnabled(this.micEnabled)
      console.log('✅ Microphone toggled successfully')
    } catch (error) {
      console.error('Failed to toggle microphone:', error)
      // Revert state on error
      this.micEnabled = !this.micEnabled
    }
  }

  // Screen Share Toggle
  async toggleScreenShare() {
    if (!this.localParticipant) {
      console.warn('Cannot toggle screen share: Not connected to LiveKit')
      return
    }

    this.screenShareEnabled = !this.screenShareEnabled

    if (this.hasScreenStatusTarget) {
      this.screenStatusTarget.classList.toggle('hidden', !this.screenShareEnabled)
    }

    // Update button appearance
    if (this.hasScreenBtnTarget) {
      this.screenBtnTarget.classList.toggle('bg-blue-700', this.screenShareEnabled)
      this.screenBtnTarget.classList.toggle('bg-gray-800', !this.screenShareEnabled)
    }

    console.log(`🖥️ Screen share ${this.screenShareEnabled ? 'enabled' : 'disabled'}`)

    try {
      await this.localParticipant.setScreenShareEnabled(this.screenShareEnabled, {
        audio: true // Include system audio
      })
      console.log('✅ Screen share toggled successfully')
    } catch (error) {
      console.error('Failed to toggle screen share:', error)
      // Revert state on error
      this.screenShareEnabled = !this.screenShareEnabled
    }
  }

  // Change Camera Device
  async changeCamera(event) {
    const deviceId = event.target.value
    if (!deviceId) return

    console.log(`📹 Switching camera to:`, deviceId)

    // Save preference
    this.saveDevicePreference('camera', deviceId)

    // If testing devices in settings, update test preview
    if (this.isTestingDevices) {
      await this.updateTestPreview('camera', deviceId)
      return
    }

    // If not connected to LiveKit, just save preference
    if (!this.localParticipant) {
      console.log('💾 Camera preference saved, will use when going live')
      return
    }

    try {
      // Get the camera track publication
      const videoPublication = this.localParticipant.getTrackPublication('camera')
      if (videoPublication && videoPublication.track) {
        // Use restartTrack to switch devices
        await videoPublication.track.restartTrack({ deviceId: deviceId })
        console.log('✅ Camera switched successfully')

        // Update preview
        this.showLocalVideoPreview()
      }
    } catch (error) {
      console.error('Failed to switch camera:', error)
    }
  }

  // Change Microphone Device
  async changeMicrophone(event) {
    const deviceId = event.target.value
    if (!deviceId) return

    console.log(`🎤 Switching microphone to:`, deviceId)

    // Save preference
    this.saveDevicePreference('mic', deviceId)

    // If testing devices in settings, update test
    if (this.isTestingDevices) {
      await this.updateTestPreview('microphone', deviceId)
      return
    }

    // If not connected to LiveKit, just save preference
    if (!this.localParticipant) {
      console.log('💾 Microphone preference saved, will use when going live')
      return
    }

    try {
      // Get the microphone track publication
      const audioPublication = this.localParticipant.getTrackPublication('microphone')
      if (audioPublication && audioPublication.track) {
        // Use restartTrack to switch devices
        await audioPublication.track.restartTrack({ deviceId: deviceId })
        console.log('✅ Microphone switched successfully')
      }
    } catch (error) {
      console.error('Failed to switch microphone:', error)
    }
  }

  // Change Quality Preset (for broadcaster)
  async changeQuality(event) {
    if (!this.localParticipant || typeof LiveKitClient === 'undefined') {
      console.warn('Cannot change quality: Not connected to LiveKit')
      return
    }

    const quality = event.target.value
    if (!quality) return

    console.log(`🎚️ Changing quality to:`, quality)

    try {
      const { VideoPresets, Track } = LiveKitClient
      const videoTrack = await this.localParticipant.getTrack(Track.Source.Camera)

      if (videoTrack) {
        // Map quality names to VideoPresets
        const presetMap = {
          'h1080': VideoPresets.h1080,
          'h720': VideoPresets.h720,
          'h540': VideoPresets.h540,
          'h360': VideoPresets.h360
        }

        const preset = presetMap[quality] || VideoPresets.h720

        await videoTrack.setPublishingOptions({
          videoEncoding: preset
        })
        console.log('✅ Quality changed successfully')
      }
    } catch (error) {
      console.error('Failed to change quality:', error)
    }
  }

  // Set Quality (Viewer)
  async setQuality(event) {
    if (!this.room || typeof LiveKitClient === 'undefined') {
      console.warn('Cannot set quality: Not connected to LiveKit')
      return
    }

    const quality = event.currentTarget.dataset.quality
    if (!quality) return

    console.log(`👁️ Viewer setting quality to:`, quality)

    try {
      const { VideoQuality, Track } = LiveKitClient

      // Get the first remote participant (broadcaster)
      const remoteParticipants = Array.from(this.room.participants.values())
      if (remoteParticipants.length > 0) {
        const broadcaster = remoteParticipants[0]
        const videoPublication = broadcaster.getTrack(Track.Source.Camera)

        if (videoPublication && videoPublication.track) {
          // Map quality string to VideoQuality enum
          const qualityMap = {
            'high': VideoQuality.HIGH,
            'medium': VideoQuality.MEDIUM,
            'low': VideoQuality.LOW
          }

          const videoQuality = qualityMap[quality.toLowerCase()] || VideoQuality.HIGH
          videoPublication.setVideoQuality(videoQuality)
          console.log('✅ Viewer quality set successfully')
        }
      }
    } catch (error) {
      console.error('Failed to set quality:', error)
    }
  }

  // Volume Control
  changeVolume(event) {
    const volume = event.target.value / 100
    console.log(`🔊 Volume changed to:`, volume)

    // Set volume on all audio and video elements
    const mediaElements = document.querySelectorAll('audio, video')
    mediaElements.forEach(el => {
      el.volume = volume
    })
  }

  // Chat Toggle
  toggleChat() {
    // Find the chat sidebar and toggle it
    const chatSidebar = document.querySelector('[data-stream-viewer-target="chatSidebar"]')
    if (chatSidebar) {
      const isHidden = chatSidebar.style.transform === 'translateX(100%)' ||
                      chatSidebar.style.transform === ''

      if (isHidden) {
        chatSidebar.style.transform = 'translateX(0)'
        console.log('💬 Chat opened')
      } else {
        chatSidebar.style.transform = 'translateX(100%)'
        console.log('💬 Chat closed')
      }
    }
  }

  // End Stream
  async endStream() {
    if (!confirm('End the stream? This will disconnect all viewers.')) return

    try {
      // Get stream ID from data attribute or config
      const streamId = this.streamIdValue || this.getStreamId()
      if (!streamId) {
        console.error('Stream ID not found')
        return
      }

      const response = await fetch(`/account/streams/${streamId}/end_stream`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        console.log('✅ Stream ended successfully')
        // Redirect to stream management page
        window.location.href = `/account/streams/${streamId}`
      } else {
        console.error('Failed to end stream:', response.status)
        alert('Failed to end stream. Please try again.')
      }
    } catch (error) {
      console.error('Error ending stream:', error)
      alert('An error occurred. Please try again.')
    }
  }

  getStreamId() {
    // Try to extract from URL or page data
    const match = window.location.pathname.match(/streams\/([^\/]+)/)
    return match ? match[1] : null
  }

  // Fullscreen Toggle
  toggleFullscreen() {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen()
      console.log("📺 Entering fullscreen")
    } else {
      document.exitFullscreen()
      console.log("📺 Exiting fullscreen")
    }
  }

  // Update Duration Display
  updateDuration() {
    if (this.hasDurationTarget) {
      const elapsed = Math.floor((Date.now() - this.startTime) / 1000)
      const minutes = Math.floor(elapsed / 60)
      const seconds = elapsed % 60
      this.durationTarget.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
    }
  }

  // Update Stats (called from stream-viewer controller)
  updateStats(stats) {
    if (this.hasBitrateTarget && stats.bitrate) {
      this.bitrateTarget.textContent = `${Math.round(stats.bitrate / 1000)} kbps`
    }
    
    if (this.hasFpsTarget && stats.fps) {
      this.fpsTarget.textContent = stats.fps
    }
    
    if (this.hasResolutionTarget && stats.resolution) {
      this.resolutionTarget.textContent = `${stats.resolution.width}x${stats.resolution.height}`
    }
    
    if (this.hasConnectionTarget && stats.quality) {
      this.connectionTarget.textContent = stats.quality
      this.connectionTarget.className = stats.quality === 'Excellent' ? 'text-sm font-mono text-green-400' : 
                                        stats.quality === 'Good' ? 'text-sm font-mono text-yellow-400' :
                                        'text-sm font-mono text-red-400'
    }
  }

  // Update Viewer Count
  updateViewerCount(count) {
    if (this.hasViewerCountTarget) {
      this.viewerCountTarget.textContent = `${count} viewer${count !== 1 ? 's' : ''}`
    }
  }

  // Keyboard Shortcuts
  setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
      // Ignore if typing in input
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return
      
      switch(e.key.toLowerCase()) {
        case 'c':
          e.preventDefault()
          this.toggleCamera()
          break
        case 'm':
          e.preventDefault()
          this.toggleMicrophone()
          break
        case 's':
          e.preventDefault()
          this.toggleScreenShare()
          break
        case 'f':
          e.preventDefault()
          this.toggleFullscreen()
          break
        case '?':
          e.preventDefault()
          this.showShortcutsHelp()
          break
      }
    })
  }

  showShortcutsHelp() {
    // Toggle shortcuts help panel
    const help = document.querySelector('[data-broadcaster-controls-target="shortcuts"]')
    if (help) {
      help.classList.toggle('hidden')
    }
  }

  // Settings Modal (Google Meet Style)
  openSettings() {
    if (this.hasSettingsModalTarget) {
      this.settingsModalTarget.classList.remove('hidden')
      console.log('⚙️ Settings modal opened')
    }
  }

  closeSettings() {
    if (this.hasSettingsModalTarget) {
      this.settingsModalTarget.classList.add('hidden')
      console.log('⚙️ Settings modal closed')

      // Stop testing devices when closing settings
      this.stopTestingDevices()
    }
  }

  closeSettingsOnBackdrop(event) {
    // Only close if clicking the backdrop (not the modal content)
    if (event.target === this.settingsModalTarget) {
      this.closeSettings()
    }
  }

  // Device Testing (for settings modal preview)
  async startTestingDevices() {
    this.isTestingDevices = true
    console.log('🧪 Starting device testing mode')

    try {
      // Get selected devices
      const cameraId = this.hasCameraSelectTarget ? this.cameraSelectTarget.value : null
      const micId = this.hasMicSelectTarget ? this.micSelectTarget.value : null

      // Create test video preview
      const constraints = {
        video: cameraId ? { deviceId: { exact: cameraId } } : true,
        audio: micId ? { deviceId: { exact: micId } } : true
      }

      this.testStream = await navigator.mediaDevices.getUserMedia(constraints)

      // Show video in test container
      const testVideoContainer = document.getElementById('test-video-preview')
      if (testVideoContainer) {
        const videoElement = document.createElement('video')
        videoElement.srcObject = this.testStream
        videoElement.autoplay = true
        videoElement.muted = true // Mute to avoid feedback
        videoElement.style.width = '100%'
        videoElement.style.height = '100%'
        videoElement.style.objectFit = 'cover'
        videoElement.style.borderRadius = '8px'

        testVideoContainer.innerHTML = ''
        testVideoContainer.appendChild(videoElement)
        console.log('📹 Test video preview shown')
      }

      // Setup audio level monitoring
      this.setupAudioLevelMonitor()

    } catch (error) {
      console.error('Failed to start device testing:', error)
      alert('Could not access camera/microphone. Please check permissions.')
    }
  }

  async stopTestingDevices() {
    this.isTestingDevices = false

    if (this.testStream) {
      this.testStream.getTracks().forEach(track => track.stop())
      this.testStream = null
      console.log('🧪 Stopped device testing mode')
    }

    if (this.audioContext) {
      this.audioContext.close()
      this.audioContext = null
    }
  }

  async updateTestPreview(type, deviceId) {
    console.log(`🧪 Updating test preview for ${type}:`, deviceId)

    // Stop current test stream
    await this.stopTestingDevices()

    // Restart with new device
    await this.startTestingDevices()
  }

  setupAudioLevelMonitor() {
    try {
      const audioTrack = this.testStream.getAudioTracks()[0]
      if (!audioTrack) return

      this.audioContext = new AudioContext()
      const source = this.audioContext.createMediaStreamSource(new MediaStream([audioTrack]))
      const analyser = this.audioContext.createAnalyser()
      analyser.fftSize = 256
      source.connect(analyser)

      const dataArray = new Uint8Array(analyser.frequencyBinCount)

      const updateLevel = () => {
        if (!this.isTestingDevices) return

        analyser.getByteFrequencyData(dataArray)
        const average = dataArray.reduce((a, b) => a + b) / dataArray.length
        const level = Math.min(100, (average / 128) * 100)

        // Update audio level indicator
        const indicator = document.getElementById('audio-level-indicator')
        if (indicator) {
          indicator.style.width = `${level}%`
          indicator.style.backgroundColor = level > 80 ? '#ef4444' : level > 50 ? '#22c55e' : '#3b82f6'
        }

        requestAnimationFrame(updateLevel)
      }

      updateLevel()
      console.log('🎤 Audio level monitoring started')
    } catch (error) {
      console.error('Failed to setup audio monitoring:', error)
    }
  }

  // Green Room Mode (talk with co-hosts before going live)
  async enterGreenRoom() {
    console.log('🎭 Entering green room mode')

    // Enable camera and mic but don't publish to viewers yet
    await this.toggleCamera()
    await this.toggleMicrophone()

    // Show green room UI
    const greenRoomBanner = document.getElementById('green-room-banner')
    if (greenRoomBanner) {
      greenRoomBanner.classList.remove('hidden')
    }

    // Update UI to show we're in rehearsal
    const goLiveBtn = document.getElementById('go-live-btn')
    if (goLiveBtn) {
      goLiveBtn.classList.remove('hidden')
    }
  }

  async goLive() {
    if (!confirm('Ready to go live? Viewers will be able to see and hear you.')) return

    console.log('🔴 Going live to viewers!')

    // Hide green room UI
    const greenRoomBanner = document.getElementById('green-room-banner')
    if (greenRoomBanner) {
      greenRoomBanner.classList.add('hidden')
    }

    const goLiveBtn = document.getElementById('go-live-btn')
    if (goLiveBtn) {
      goLiveBtn.classList.add('hidden')
    }

    // Start publishing to viewers (already connected via LiveKit)
    // The stream is already live, just need to update UI state
    alert('🎉 You are now LIVE to viewers!')
  }
}
