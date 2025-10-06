import { Controller } from "@hotwired/stimulus"

// Professional Broadcaster Controls for LiveKit Streaming
// Implements device switching, quality control, and monitoring
export default class extends Controller {
  static targets = [
    "cameraBtn", "micBtn", "screenBtn",
    "cameraStatus", "micStatus", "screenStatus",
    "cameraSelect", "micSelect", "qualitySelect",
    "noiseSuppression", "echoCancellation",
    "viewerCount", "duration", "bitrate", "fps", "resolution", "connection"
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
      
      // Populate camera dropdown
      const cameras = devices.filter(d => d.kind === 'videoinput')
      if (this.hasCameraSelectTarget) {
        this.cameraSelectTarget.innerHTML = '<option value="">Select Camera...</option>'
        cameras.forEach((device, index) => {
          const option = document.createElement('option')
          option.value = device.deviceId
          option.textContent = device.label || `Camera ${index + 1}`
          this.cameraSelectTarget.appendChild(option)
        })
      }
      
      // Populate microphone dropdown
      const mics = devices.filter(d => d.kind === 'audioinput')
      if (this.hasMicSelectTarget) {
        this.micSelectTarget.innerHTML = '<option value="">Select Microphone...</option>'
        mics.forEach((device, index) => {
          const option = document.createElement('option')
          option.value = device.deviceId
          option.textContent = device.label || `Microphone ${index + 1}`
          this.micSelectTarget.appendChild(option)
        })
      }
      
      console.log(`📹 Found ${cameras.length} cameras, 🎤 ${mics.length} microphones`)
    } catch (error) {
      console.error("Failed to enumerate devices:", error)
    }
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

    // Get camera track
    const cameraPublication = this.localParticipant.getTrack('camera')
    if (cameraPublication && cameraPublication.track) {
      const videoElement = cameraPublication.track.attach()
      videoElement.id = 'local-video-preview'
      videoElement.style.width = '100%'
      videoElement.style.height = '100%'
      videoElement.style.objectFit = 'contain'
      videoElement.style.backgroundColor = 'black'

      // Clear container and add preview
      videoContainer.innerHTML = ''
      videoContainer.appendChild(videoElement)

      console.log('📹 Local video preview shown')
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
    if (!this.localParticipant) {
      console.warn('Cannot change camera: Not connected to LiveKit')
      return
    }

    const deviceId = event.target.value
    if (!deviceId) return

    console.log(`📹 Switching camera to:`, deviceId)

    try {
      await this.localParticipant.switchActiveDevice('videoinput', deviceId)
      console.log('✅ Camera switched successfully')
    } catch (error) {
      console.error('Failed to switch camera:', error)
    }
  }

  // Change Microphone Device
  async changeMicrophone(event) {
    if (!this.localParticipant) {
      console.warn('Cannot change microphone: Not connected to LiveKit')
      return
    }

    const deviceId = event.target.value
    if (!deviceId) return

    console.log(`🎤 Switching microphone to:`, deviceId)

    try {
      await this.localParticipant.switchActiveDevice('audioinput', deviceId)
      console.log('✅ Microphone switched successfully')
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
}
