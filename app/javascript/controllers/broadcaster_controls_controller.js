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
    
    // Enumerate available devices
    this.enumerateDevices()
    
    // Start duration timer
    this.updateDuration()
    this.durationInterval = setInterval(() => this.updateDuration(), 1000)
    
    // Setup keyboard shortcuts
    this.setupKeyboardShortcuts()
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
    
    // TODO: Integrate with LiveKit
    // await this.localParticipant.setCameraEnabled(this.cameraEnabled)
  }

  // Microphone Toggle
  async toggleMicrophone() {
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
    
    // TODO: Integrate with LiveKit
    // await this.localParticipant.setMicrophoneEnabled(this.micEnabled)
  }

  // Screen Share Toggle
  async toggleScreenShare() {
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
    
    // TODO: Integrate with LiveKit
    // await this.localParticipant.setScreenShareEnabled(this.screenShareEnabled, { audio: true })
  }

  // Change Camera Device
  async changeCamera(event) {
    const deviceId = event.target.value
    console.log(`📹 Switching camera to:`, deviceId)
    
    // TODO: Integrate with LiveKit
    // await this.localParticipant.switchActiveDevice('videoinput', deviceId)
  }

  // Change Microphone Device
  async changeMicrophone(event) {
    const deviceId = event.target.value
    console.log(`🎤 Switching microphone to:`, deviceId)
    
    // TODO: Integrate with LiveKit
    // await this.localParticipant.switchActiveDevice('audioinput', deviceId)
  }

  // Change Quality Preset
  async changeQuality(event) {
    const quality = event.target.value
    console.log(`🎚️ Changing quality to:`, quality)
    
    // TODO: Integrate with LiveKit VideoPresets
    // await this.localParticipant.setTrackPublishOptions(videoTrack, {
    //   videoEncoding: VideoPresets[quality]
    // })
  }

  // Set Quality (Viewer)
  async setQuality(event) {
    const quality = event.currentTarget.dataset.quality
    console.log(`👁️ Viewer setting quality to:`, quality)
    
    // TODO: Integrate with LiveKit
    // const videoTrack = this.remoteParticipant.getTrack(Track.Source.Camera)
    // await videoTrack.setVideoQuality(VideoQuality[quality.toUpperCase()])
  }

  // Volume Control
  changeVolume(event) {
    const volume = event.target.value / 100
    console.log(`🔊 Volume changed to:`, volume)
    
    // TODO: Set audio element volume
    // const audioElements = document.querySelectorAll('audio')
    // audioElements.forEach(el => el.volume = volume)
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
