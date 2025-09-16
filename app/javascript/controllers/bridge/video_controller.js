import { Controller } from "@hotwired/stimulus"

// Mobile bridge controller for native video streaming
// Connects to data-controller="bridge--video" 
export default class extends Controller {
  static targets = ["player", "controls", "statusIndicator"]
  static values = { 
    streamId: String,
    roomUrl: String,
    accessToken: String,
    roomName: String,
    participantIdentity: String,
    participantName: String,
    canPublish: Boolean,
    platform: String
  }

  connect() {
    this.isNativeApp = this.isHotwireNativeApp()
    this.isMobile = this.isMobileDevice()
    
    console.log(`Video Bridge: Platform=${this.platformValue}, Native=${this.isNativeApp}, Mobile=${this.isMobile}`)
    
    // Set up event listeners first
    this.setupEventListeners()
    
    // Wait for video token before initializing player
    if (this.roomUrlValue && this.accessTokenValue) {
      this.initializePlayer()
    } else {
      console.log("Waiting for video token...")
      this.updatePlayerState('waiting_for_token')
    }
  }

  // Handle video token received event
  videoTokenReceived(event) {
    const data = event.detail
    console.log("Video token received:", data)
    
    // Update values from token response
    this.roomUrlValue = data.room_url
    this.accessTokenValue = data.access_token
    this.roomNameValue = data.room_name
    this.participantIdentityValue = data.participant_identity
    this.participantNameValue = data.participant_name
    
    // Now initialize the player
    this.initializePlayer()
  }

  // Initialize player based on platform
  initializePlayer() {
    if (this.isNativeApp) {
      this.initializeNativePlayer()
    } else {
      this.initializeWebPlayer()
    }
  }

  disconnect() {
    this.cleanup()
  }

  // Native mobile video player integration
  async initializeNativePlayer() {
    try {
      console.log("Initializing native video player...")
      
      const videoConfig = {
        streamId: this.streamIdValue,
        roomUrl: this.roomUrlValue,
        accessToken: this.accessTokenValue,
        roomName: this.roomNameValue,
        participantIdentity: this.participantIdentityValue,
        participantName: this.participantNameValue,
        canPublish: this.canPublishValue,
        
        // Mobile-specific optimizations
        videoConfig: {
          resolution: { width: 1280, height: 720 },
          frameRate: 30,
          bitrate: 2000000, // 2 Mbps
          codec: 'h264'
        },
        
        audioConfig: {
          bitrate: 128000, // 128 kbps
          codec: 'opus',
          sampleRate: 48000
        },
        
        // Background/PiP support
        backgroundMode: {
          enabled: true,
          audioOnly: true
        },
        
        pictureInPicture: {
          enabled: true,
          aspectRatio: '16:9'
        },
        
        // UI preferences
        showControls: true,
        autoplay: true,
        muted: false
      }

      // Send configuration to native layer via Hotwire Native bridge
      if (window.HotwireNative) {
        // Configure native features
        await this.configureBackgroundAudio()
        await this.configurePictureInPicture()
        
        const result = await this.bridgeCall("initializeVideoPlayer", videoConfig)
        
        if (result.success) {
          this.updatePlayerState('initialized')
          console.log("Native video player initialized successfully")
          
          // Set up advanced features
          this.setupPictureInPictureHandlers()
          this.initializeAdaptiveBitrate()
          
          // Connect to LiveKit room
          await this.connectToRoom()
        } else {
          throw new Error(result.error || "Failed to initialize native player")
        }
      } else {
        console.warn("HotwireNative not available, falling back to web player")
        this.initializeWebPlayer()
      }

    } catch (error) {
      console.error("Failed to initialize native player:", error)
      this.updatePlayerState('error', error.message)
      
      // Fallback to web player
      this.initializeWebPlayer()
    }
  }

  // Web player fallback (simplified LiveKit web integration)
  async initializeWebPlayer() {
    try {
      console.log("Initializing web video player...")
      
      // Create placeholder for web player
      if (this.hasPlayerTarget) {
        this.playerTarget.innerHTML = `
          <div class="web-video-player bg-black rounded-lg aspect-video flex items-center justify-center">
            <div class="text-center text-white">
              <div class="w-16 h-16 mx-auto mb-4 bg-white bg-opacity-20 rounded-full flex items-center justify-center">
                <svg class="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M8 5v14l11-7z"/>
                </svg>
              </div>
              <h3 class="text-lg font-semibold mb-2">Web Video Player</h3>
              <p class="text-sm text-gray-300">Connecting to stream...</p>
              <div class="mt-4">
                <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-white mx-auto"></div>
              </div>
            </div>
          </div>
        `
      }
      
      this.updatePlayerState('connecting')
      
      // Import LiveKit web SDK dynamically
      const { Room, RemoteTrack, RemoteVideoTrack, RemoteAudioTrack } = await import('livekit-client')
      
      // Create LiveKit room
      this.room = new Room({
        adaptiveStream: true,
        dynacast: true,
        videoCaptureDefaults: {
          resolution: { width: 1280, height: 720 },
          facingMode: 'user'
        }
      })
      
      // Set up room event listeners
      this.setupRoomEvents()
      
      // Connect to room
      await this.room.connect(this.roomUrlValue, this.accessTokenValue)
      
      // Set up advanced features for web
      this.setupPictureInPictureHandlers()
      this.initializeAdaptiveBitrate()
      
      this.updatePlayerState('connected')
      console.log("Web video player connected successfully")
      
    } catch (error) {
      console.error("Failed to initialize web player:", error)
      this.updatePlayerState('error', error.message)
    }
  }

  // Connect to LiveKit room (for native player)
  async connectToRoom() {
    try {
      const result = await this.bridgeCall("connectToRoom", {
        roomUrl: this.roomUrlValue,
        accessToken: this.accessTokenValue
      })
      
      if (result.success) {
        this.updatePlayerState('connected')
        console.log("Connected to LiveKit room")
      } else {
        throw new Error(result.error || "Failed to connect to room")
      }
      
    } catch (error) {
      console.error("Failed to connect to room:", error)
      this.updatePlayerState('error', error.message)
    }
  }

  // Setup room event listeners for web player
  setupRoomEvents() {
    if (!this.room) return
    
    this.room.on('participantConnected', (participant) => {
      console.log('Participant connected:', participant.identity)
      this.handleParticipantConnected(participant)
    })
    
    this.room.on('participantDisconnected', (participant) => {
      console.log('Participant disconnected:', participant.identity)
      this.handleParticipantDisconnected(participant)
    })
    
    this.room.on('trackSubscribed', (track, publication, participant) => {
      console.log('Track subscribed:', track.kind, participant.identity)
      this.handleTrackSubscribed(track, participant)
    })
    
    this.room.on('trackUnsubscribed', (track, publication, participant) => {
      console.log('Track unsubscribed:', track.kind, participant.identity)
      this.handleTrackUnsubscribed(track, participant)
    })
    
    this.room.on('disconnected', () => {
      console.log('Disconnected from room')
      this.updatePlayerState('disconnected')
    })
    
    this.room.on('reconnecting', () => {
      console.log('Reconnecting to room')
      this.updatePlayerState('reconnecting')
    })
    
    this.room.on('reconnected', () => {
      console.log('Reconnected to room')
      this.updatePlayerState('connected')
    })
  }

  // Handle participant connected
  handleParticipantConnected(participant) {
    // Notify native layer if available
    if (this.isNativeApp) {
      this.bridgeCall("onParticipantConnected", {
        identity: participant.identity,
        name: participant.name
      })
    }
    
    // Update UI
    this.updateParticipantList()
  }

  // Handle participant disconnected
  handleParticipantDisconnected(participant) {
    if (this.isNativeApp) {
      this.bridgeCall("onParticipantDisconnected", {
        identity: participant.identity
      })
    }
    
    this.updateParticipantList()
  }

  // Handle track subscribed (video/audio)
  handleTrackSubscribed(track, participant) {
    if (track instanceof RemoteVideoTrack) {
      console.log('Video track received from:', participant.identity)
      
      if (this.isNativeApp) {
        // Let native player handle video rendering
        this.bridgeCall("onVideoTrackReceived", {
          participantIdentity: participant.identity,
          trackSid: track.sid
        })
      } else {
        // Render video in web player
        this.renderVideoTrack(track, participant)
      }
    } else if (track instanceof RemoteAudioTrack) {
      console.log('Audio track received from:', participant.identity)
      
      if (this.isNativeApp) {
        this.bridgeCall("onAudioTrackReceived", {
          participantIdentity: participant.identity,
          trackSid: track.sid
        })
      } else {
        // Attach audio element for web
        const audioElement = track.attach()
        audioElement.play()
      }
    }
  }

  // Handle track unsubscribed
  handleTrackUnsubscribed(track, participant) {
    if (this.isNativeApp) {
      this.bridgeCall("onTrackUnsubscribed", {
        participantIdentity: participant.identity,
        trackSid: track.sid,
        trackKind: track.kind
      })
    } else {
      // Remove from web UI
      track.detach()
    }
  }

  // Render video track in web player
  renderVideoTrack(track, participant) {
    if (!this.hasPlayerTarget) return
    
    const videoElement = track.attach()
    videoElement.className = 'w-full h-full object-cover rounded-lg'
    videoElement.autoplay = true
    videoElement.playsInline = true
    
    // Replace placeholder with actual video
    this.playerTarget.innerHTML = ''
    this.playerTarget.appendChild(videoElement)
  }

  // Player control methods
  async toggleMute() {
    if (this.isNativeApp) {
      await this.bridgeCall("toggleMute")
    } else if (this.room) {
      const audioTrack = this.room.localParticipant.getTrackPublication('audio')
      if (audioTrack) {
        await audioTrack.setMuted(!audioTrack.isMuted)
      }
    }
  }

  async toggleVideo() {
    if (this.isNativeApp) {
      await this.bridgeCall("toggleVideo")
    } else if (this.room) {
      const videoTrack = this.room.localParticipant.getTrackPublication('video')
      if (videoTrack) {
        await videoTrack.setMuted(!videoTrack.isMuted)
      }
    }
  }

  async switchCamera() {
    if (this.isNativeApp) {
      await this.bridgeCall("switchCamera")
    }
    // Web camera switching would require additional implementation
  }

  async enterPictureInPicture() {
    try {
      console.log("Entering Picture-in-Picture mode...")
      
      if (this.isNativeApp) {
        // Native PiP with enhanced configuration
        const result = await this.bridgeCall("enterPictureInPicture", {
          aspectRatio: "16:9",
          showPlaybackControls: true,
          allowsMediaControl: true,
          backgroundColor: "#000000",
          contentInsets: { top: 0, left: 0, bottom: 0, right: 0 },
          // iOS specific
          preferredTimeSamplingSize: { width: 1280, height: 720 },
          // Android specific
          allowAutoEnterPictureInPicture: true,
          seamlessResize: true
        })
        
        if (result.success) {
          this.isPiPActive = true
          this.updatePlayerState('picture_in_picture', 'Picture-in-Picture active')
          this.showPiPNotification("Video minimized to Picture-in-Picture")
        } else {
          throw new Error(result.error || "Failed to enter Picture-in-Picture")
        }
        
      } else {
        // Web PiP implementation
        const videoElement = this.playerTarget.querySelector('video')
        
        if (videoElement && videoElement.requestPictureInPicture) {
          // Check if PiP is supported and not already active
          if (document.pictureInPictureEnabled && !document.pictureInPictureElement) {
            await videoElement.requestPictureInPicture()
            this.isPiPActive = true
            this.updatePlayerState('picture_in_picture', 'Picture-in-Picture active')
            this.showPiPNotification("Video minimized to Picture-in-Picture")
          } else {
            throw new Error("Picture-in-Picture not available")
          }
        } else {
          throw new Error("Video element not found or PiP not supported")
        }
      }
      
    } catch (error) {
      console.error("Failed to enter Picture-in-Picture:", error)
      this.showNotification(`Picture-in-Picture failed: ${error.message}`, "error")
    }
  }

  async exitPictureInPicture() {
    try {
      console.log("Exiting Picture-in-Picture mode...")
      
      if (this.isNativeApp) {
        const result = await this.bridgeCall("exitPictureInPicture")
        
        if (result.success) {
          this.isPiPActive = false
          this.updatePlayerState('connected', 'Full screen restored')
          this.showPiPNotification("Picture-in-Picture closed")
        } else {
          throw new Error(result.error || "Failed to exit Picture-in-Picture")
        }
        
      } else if (document.pictureInPictureElement) {
        await document.exitPictureInPicture()
        this.isPiPActive = false
        this.updatePlayerState('connected', 'Full screen restored')
        this.showPiPNotification("Picture-in-Picture closed")
        
      } else {
        console.log("Picture-in-Picture not currently active")
      }
      
    } catch (error) {
      console.error("Failed to exit Picture-in-Picture:", error)
      this.showNotification(`Failed to exit Picture-in-Picture: ${error.message}`, "error")
    }
  }

  // Configure Picture-in-Picture settings
  async configurePictureInPicture() {
    if (!this.isNativeApp) return
    
    try {
      await this.bridgeCall("configurePictureInPicture", {
        // iOS AVPictureInPictureController configuration
        canStartPictureInPictureAutomaticallyFromInline: true,
        requiresLinearPlayback: false,
        
        // Android PictureInPictureParams
        aspectRatio: { numerator: 16, denominator: 9 },
        sourceRectHint: null, // Will be calculated automatically
        autoEnterEnabled: true,
        seamlessResizeEnabled: true,
        
        // Common settings
        playbackControls: {
          play: true,
          pause: true,
          skipForward: false,
          skipBackward: false,
          mute: true,
          volume: true
        },
        
        // Background behavior
        continueInBackground: true,
        pauseWhenBackgrounded: false
      })
      
      console.log("Picture-in-Picture configured successfully")
      
    } catch (error) {
      console.error("Failed to configure Picture-in-Picture:", error)
    }
  }

  // Handle automatic PiP triggers
  setupPictureInPictureHandlers() {
    if (this.isNativeApp) {
      // Listen for native PiP events
      this.addEventListener("pictureInPictureDidStart", this.handlePiPStart.bind(this))
      this.addEventListener("pictureInPictureDidStop", this.handlePiPStop.bind(this))
      this.addEventListener("pictureInPictureWillStart", this.handlePiPWillStart.bind(this))
      this.addEventListener("pictureInPictureWillStop", this.handlePiPWillStop.bind(this))
    } else {
      // Web PiP event listeners
      const videoElement = this.playerTarget.querySelector('video')
      if (videoElement) {
        videoElement.addEventListener('enterpictureinpicture', this.handlePiPStart.bind(this))
        videoElement.addEventListener('leavepictureinpicture', this.handlePiPStop.bind(this))
      }
    }
    
    // Listen for app lifecycle events for auto-PiP
    document.addEventListener('visibilitychange', this.handleAutoEnterPiP.bind(this))
  }

  // Handle auto-enter PiP when app goes to background
  async handleAutoEnterPiP() {
    if (document.hidden && this.room && !this.isPiPActive) {
      // Only auto-enter PiP if actively watching a stream
      const hasActiveVideo = this.room.participants.size > 0
      
      if (hasActiveVideo && this.isNativeApp) {
        console.log("App backgrounded with active stream - auto-entering PiP")
        await this.enterPictureInPicture()
      }
    }
  }

  // PiP event handlers
  handlePiPStart(event) {
    console.log("Picture-in-Picture started")
    this.isPiPActive = true
    this.updatePlayerState('picture_in_picture', 'Picture-in-Picture active')
    
    // Optimize for PiP mode
    if (this.isNativeApp) {
      this.bridgeCall("optimizeForPictureInPicture", {
        reduceVideoQuality: false, // Keep high quality in PiP
        maintainAspectRatio: true,
        showStreamTitle: true
      })
    }
  }

  handlePiPStop(event) {
    console.log("Picture-in-Picture stopped")
    this.isPiPActive = false
    this.updatePlayerState('connected', 'Full screen mode')
    
    // Restore full screen optimizations
    if (this.isNativeApp) {
      this.bridgeCall("restoreFromPictureInPicture", {
        restoreVideoQuality: true,
        refreshUI: true
      })
    }
  }

  handlePiPWillStart(event) {
    console.log("Picture-in-Picture will start")
    // Prepare for PiP transition
  }

  handlePiPWillStop(event) {
    console.log("Picture-in-Picture will stop")
    // Prepare for full screen transition
  }

  // Show PiP-specific notifications
  showPiPNotification(message) {
    // Create a smaller, PiP-friendly notification
    const notification = document.createElement('div')
    notification.className = 'fixed bottom-4 left-4 max-w-xs p-3 bg-black bg-opacity-75 text-white text-sm rounded-lg z-50 transition-opacity duration-300'
    notification.textContent = message
    
    document.body.appendChild(notification)
    
    setTimeout(() => {
      notification.style.opacity = '0'
      setTimeout(() => {
        if (document.body.contains(notification)) {
          document.body.removeChild(notification)
        }
      }, 300)
    }, 2000)
  }

  async toggleFullscreen() {
    if (this.isNativeApp) {
      await this.bridgeCall("toggleFullscreen")
    } else {
      const videoElement = this.playerTarget.querySelector('video')
      if (videoElement) {
        if (document.fullscreenElement) {
          await document.exitFullscreen()
        } else {
          await videoElement.requestFullscreen()
        }
      }
    }
  }

  // Start broadcasting (for creators)
  async startBroadcast(event) {
    const streamId = event.target.dataset.streamId || this.streamIdValue
    
    try {
      console.log("Starting broadcast for stream:", streamId)
      this.updatePlayerState('starting_broadcast')
      
      const response = await fetch(`/account/streams/${streamId}/start_stream`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        console.log("Broadcast started successfully:", data)
        
        // Update connection info
        this.roomUrlValue = data.room_url
        this.accessTokenValue = data.access_token
        this.roomNameValue = data.room_name
        this.participantIdentityValue = data.participant_identity
        this.participantNameValue = data.participant_name
        
        // Initialize player for broadcasting
        this.initializePlayer()
        
        // Show success message
        this.showNotification("Stream started successfully!", "success")
        
        // Reload page to update stream status
        setTimeout(() => {
          window.location.reload()
        }, 2000)
        
      } else {
        throw new Error(data.message || "Failed to start broadcast")
      }
      
    } catch (error) {
      console.error("Failed to start broadcast:", error)
      this.updatePlayerState('error', error.message)
      this.showNotification(`Failed to start stream: ${error.message}`, "error")
    }
  }

  // Stop broadcasting (for creators)
  async stopBroadcast() {
    const streamId = this.streamIdValue
    
    try {
      console.log("Stopping broadcast for stream:", streamId)
      
      const response = await fetch(`/account/streams/${streamId}/stop_stream`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        console.log("Broadcast stopped successfully")
        this.cleanup()
        this.updatePlayerState('offline')
        this.showNotification("Stream stopped successfully!", "success")
        
        // Reload page to update stream status
        setTimeout(() => {
          window.location.reload()
        }, 1000)
        
      } else {
        throw new Error(data.message || "Failed to stop broadcast")
      }
      
    } catch (error) {
      console.error("Failed to stop broadcast:", error)
      this.showNotification(`Failed to stop stream: ${error.message}`, "error")
    }
  }

  // Show notification to user
  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 max-w-sm p-4 rounded-lg shadow-lg z-50 transform transition-transform duration-300 ${
      type === 'success' ? 'bg-green-500 text-white' :
      type === 'error' ? 'bg-red-500 text-white' :
      'bg-blue-500 text-white'
    }`
    notification.textContent = message
    
    // Add to page
    document.body.appendChild(notification)
    
    // Slide in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)'
    }, 100)
    
    // Remove after delay
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 3000)
  }

  // Get CSRF token
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  // ==================== ADAPTIVE BITRATE CONFIGURATION ====================

  // Initialize adaptive bitrate monitoring
  initializeAdaptiveBitrate() {
    console.log("Initializing adaptive bitrate configuration...")
    
    // Initialize network monitoring
    this.networkMonitor = {
      connection: navigator.connection || navigator.mozConnection || navigator.webkitConnection,
      quality: 'unknown',
      bandwidth: 0,
      rtt: 0,
      lastCheck: Date.now()
    }
    
    // Set up periodic quality monitoring
    this.qualityCheckInterval = setInterval(() => {
      this.checkAndAdjustQuality()
    }, 5000) // Check every 5 seconds
    
    // Configure initial quality based on device and network
    this.configureInitialQuality()
    
    // Set up network change listeners
    this.setupNetworkListeners()
  }

  // Configure initial video quality based on device capabilities
  async configureInitialQuality() {
    try {
      const deviceProfile = this.detectDeviceProfile()
      const networkQuality = this.detectNetworkQuality()
      
      console.log(`Device profile: ${deviceProfile}, Network: ${networkQuality}`)
      
      // Determine optimal quality settings
      const qualitySettings = this.calculateOptimalQuality(deviceProfile, networkQuality)
      
      if (this.isNativeApp) {
        // Configure native adaptive bitrate
        await this.configureNativeAdaptiveBitrate(qualitySettings)
      } else if (this.room) {
        // Configure web player adaptive bitrate
        await this.configureWebAdaptiveBitrate(qualitySettings)
      }
      
      console.log("Initial quality configured:", qualitySettings)
      
    } catch (error) {
      console.error("Failed to configure initial quality:", error)
    }
  }

  // Detect device capabilities
  detectDeviceProfile() {
    const screen = window.screen
    const devicePixelRatio = window.devicePixelRatio || 1
    const screenWidth = screen.width * devicePixelRatio
    const screenHeight = screen.height * devicePixelRatio
    
    // Determine device tier based on capabilities
    if (this.isNativeApp) {
      // Mobile device classification
      if (screenWidth >= 2400 || screenHeight >= 2400) {
        return 'premium' // iPhone Pro, high-end Android
      } else if (screenWidth >= 1920 || screenHeight >= 1920) {
        return 'high' // iPhone standard, mid-range Android
      } else {
        return 'standard' // Older or budget devices
      }
    } else {
      // Web device classification
      const memory = navigator.deviceMemory || 4
      const cores = navigator.hardwareConcurrency || 4
      
      if (memory >= 8 && cores >= 8) {
        return 'premium'
      } else if (memory >= 4 && cores >= 4) {
        return 'high'
      } else {
        return 'standard'
      }
    }
  }

  // Detect network quality
  detectNetworkQuality() {
    if (!this.networkMonitor.connection) {
      return 'unknown'
    }
    
    const connection = this.networkMonitor.connection
    const effectiveType = connection.effectiveType
    const downlink = connection.downlink
    const rtt = connection.rtt
    
    // Store for monitoring
    this.networkMonitor.bandwidth = downlink
    this.networkMonitor.rtt = rtt
    
    // Classify network quality
    if (effectiveType === '4g' && downlink >= 10 && rtt < 100) {
      return 'excellent' // High-speed 4G/5G
    } else if (effectiveType === '4g' && downlink >= 5) {
      return 'good' // Standard 4G
    } else if (effectiveType === '3g' || downlink >= 1.5) {
      return 'fair' // 3G or slow 4G
    } else {
      return 'poor' // 2G or very slow connection
    }
  }

  // Calculate optimal quality settings
  calculateOptimalQuality(deviceProfile, networkQuality) {
    const qualityMatrix = {
      premium: {
        excellent: { resolution: '1920x1080', bitrate: 4000000, framerate: 60 },
        good: { resolution: '1920x1080', bitrate: 3000000, framerate: 30 },
        fair: { resolution: '1280x720', bitrate: 2000000, framerate: 30 },
        poor: { resolution: '854x480', bitrate: 800000, framerate: 30 }
      },
      high: {
        excellent: { resolution: '1920x1080', bitrate: 3000000, framerate: 30 },
        good: { resolution: '1280x720', bitrate: 2000000, framerate: 30 },
        fair: { resolution: '1280x720', bitrate: 1500000, framerate: 30 },
        poor: { resolution: '854x480', bitrate: 600000, framerate: 24 }
      },
      standard: {
        excellent: { resolution: '1280x720', bitrate: 2000000, framerate: 30 },
        good: { resolution: '1280x720', bitrate: 1500000, framerate: 30 },
        fair: { resolution: '854x480', bitrate: 800000, framerate: 24 },
        poor: { resolution: '640x360', bitrate: 400000, framerate: 20 }
      }
    }
    
    return qualityMatrix[deviceProfile]?.[networkQuality] || qualityMatrix.standard.fair
  }

  // Configure native adaptive bitrate
  async configureNativeAdaptiveBitrate(qualitySettings) {
    try {
      const config = {
        // Video encoding settings
        videoEncoder: {
          resolution: qualitySettings.resolution,
          bitrate: qualitySettings.bitrate,
          framerate: qualitySettings.framerate,
          codec: 'h264', // Most compatible for mobile
          profile: 'baseline',
          keyFrameInterval: 2000 // 2 second keyframes
        },
        
        // Adaptive settings
        adaptiveStream: {
          enabled: true,
          minBitrate: Math.floor(qualitySettings.bitrate * 0.3),
          maxBitrate: Math.floor(qualitySettings.bitrate * 1.5),
          qualityLevels: [
            { resolution: '640x360', bitrate: 400000 },
            { resolution: '854x480', bitrate: 800000 },
            { resolution: '1280x720', bitrate: 1500000 },
            { resolution: '1920x1080', bitrate: 3000000 }
          ]
        },
        
        // Network adaptation
        networkAdaptation: {
          enabled: true,
          bandwidthProbing: true,
          rttThreshold: 300, // Switch to lower quality if RTT > 300ms
          packetLossThreshold: 0.05, // 5% packet loss threshold
          qualityChangeDelay: 3000 // Wait 3s before quality changes
        }
      }
      
      const result = await this.bridgeCall("configureAdaptiveBitrate", config)
      
      if (result.success) {
        console.log("Native adaptive bitrate configured successfully")
        this.currentQuality = qualitySettings
      } else {
        throw new Error(result.error || "Failed to configure adaptive bitrate")
      }
      
    } catch (error) {
      console.error("Failed to configure native adaptive bitrate:", error)
    }
  }

  // Configure web adaptive bitrate
  async configureWebAdaptiveBitrate(qualitySettings) {
    if (!this.room) return
    
    try {
      // Parse resolution
      const [width, height] = qualitySettings.resolution.split('x').map(Number)
      
      // Configure video capture constraints
      const videoConstraints = {
        width: { ideal: width, max: width },
        height: { ideal: height, max: height },
        frameRate: { ideal: qualitySettings.framerate, max: qualitySettings.framerate }
      }
      
      // Get local video track
      const videoTrack = this.room.localParticipant.getTrackPublication('camera')
      
      if (videoTrack && videoTrack.track) {
        // Update track constraints
        await videoTrack.track.setMediaStreamTrack(
          await navigator.mediaDevices.getUserMedia({ 
            video: videoConstraints,
            audio: false 
          }).then(stream => stream.getVideoTracks()[0])
        )
        
        // Configure encoding parameters if supported
        if (videoTrack.track.sender) {
          const params = videoTrack.track.sender.getParameters()
          
          if (params.encodings && params.encodings.length > 0) {
            params.encodings[0].maxBitrate = qualitySettings.bitrate
            params.encodings[0].maxFramerate = qualitySettings.framerate
            
            await videoTrack.track.sender.setParameters(params)
          }
        }
      }
      
      console.log("Web adaptive bitrate configured successfully")
      this.currentQuality = qualitySettings
      
    } catch (error) {
      console.error("Failed to configure web adaptive bitrate:", error)
    }
  }

  // Periodically check and adjust quality
  async checkAndAdjustQuality() {
    if (!this.room && !this.isNativeApp) return
    
    try {
      // Get current network conditions
      const currentNetworkQuality = this.detectNetworkQuality()
      
      // Check if quality adjustment is needed
      if (this.shouldAdjustQuality(currentNetworkQuality)) {
        console.log(`Network quality changed to: ${currentNetworkQuality}`)
        
        const deviceProfile = this.detectDeviceProfile()
        const newQualitySettings = this.calculateOptimalQuality(deviceProfile, currentNetworkQuality)
        
        // Apply new quality settings
        if (this.isNativeApp) {
          await this.adjustNativeQuality(newQualitySettings)
        } else {
          await this.adjustWebQuality(newQualitySettings)
        }
        
        // Update UI indicator
        this.updateQualityIndicator(newQualitySettings)
      }
      
    } catch (error) {
      console.error("Failed to check and adjust quality:", error)
    }
  }

  // Determine if quality should be adjusted
  shouldAdjustQuality(currentNetworkQuality) {
    if (!this.currentQuality) return true
    
    // Check network quality change
    if (this.networkMonitor.quality !== currentNetworkQuality) {
      this.networkMonitor.quality = currentNetworkQuality
      return true
    }
    
    // Check RTT degradation
    if (this.networkMonitor.rtt > 500) {
      return true
    }
    
    // Check bandwidth degradation
    if (this.networkMonitor.bandwidth < 1) {
      return true
    }
    
    return false
  }

  // Adjust native quality
  async adjustNativeQuality(newQualitySettings) {
    try {
      const result = await this.bridgeCall("adjustVideoQuality", {
        resolution: newQualitySettings.resolution,
        bitrate: newQualitySettings.bitrate,
        framerate: newQualitySettings.framerate,
        smooth: true // Enable smooth transitions
      })
      
      if (result.success) {
        this.currentQuality = newQualitySettings
        console.log("Native quality adjusted to:", newQualitySettings)
      }
      
    } catch (error) {
      console.error("Failed to adjust native quality:", error)
    }
  }

  // Adjust web quality
  async adjustWebQuality(newQualitySettings) {
    // Similar to configureWebAdaptiveBitrate but for runtime adjustment
    await this.configureWebAdaptiveBitrate(newQualitySettings)
  }

  // Update quality indicator in UI
  updateQualityIndicator(qualitySettings) {
    const qualityTarget = this.element.querySelector('[data-bridge--video-target="connectionQuality"]')
    
    if (qualityTarget) {
      const resolution = qualitySettings.resolution
      const qualityLabel = this.getQualityLabel(resolution)
      
      qualityTarget.textContent = qualityLabel
      qualityTarget.title = `${resolution} @ ${qualitySettings.framerate}fps, ${Math.round(qualitySettings.bitrate / 1000)}kbps`
    }
  }

  // Get human-readable quality label
  getQualityLabel(resolution) {
    const qualityMap = {
      '1920x1080': 'HD',
      '1280x720': 'HD',
      '854x480': 'SD',
      '640x360': 'SD',
      '480x270': 'LD'
    }
    
    return qualityMap[resolution] || 'AUTO'
  }

  // Set up network change listeners
  setupNetworkListeners() {
    if (this.networkMonitor.connection) {
      this.networkMonitor.connection.addEventListener('change', () => {
        console.log("Network connection changed")
        this.checkAndAdjustQuality()
      })
    }
    
    // Listen for online/offline events
    window.addEventListener('online', () => {
      console.log("Connection restored")
      this.checkAndAdjustQuality()
    })
    
    window.addEventListener('offline', () => {
      console.log("Connection lost")
      this.updatePlayerState('disconnected', 'No internet connection')
    })
  }

  // Manual quality override (for user preference)
  async setManualQuality(resolution, bitrate, framerate) {
    console.log(`Setting manual quality: ${resolution}`)
    
    const qualitySettings = { resolution, bitrate, framerate }
    
    if (this.isNativeApp) {
      await this.adjustNativeQuality(qualitySettings)
    } else {
      await this.adjustWebQuality(qualitySettings)
    }
    
    // Disable automatic quality adjustment temporarily
    this.manualQualityOverride = true
    setTimeout(() => {
      this.manualQualityOverride = false
    }, 60000) // Re-enable auto quality after 1 minute
  }

  // Event listener setup
  setupEventListeners() {
    // Listen for native events
    if (this.isNativeApp) {
      this.addEventListener("videoPlayerStateChanged", this.handleNativeStateChange.bind(this))
      this.addEventListener("videoPlayerError", this.handleNativeError.bind(this))
      this.addEventListener("participantJoined", this.handleNativeParticipantEvent.bind(this))
      this.addEventListener("participantLeft", this.handleNativeParticipantEvent.bind(this))
    }
    
    // Listen for visibility changes (background/foreground)
    document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this))
  }

  // Handle native state changes
  handleNativeStateChange(event) {
    const { state, message } = event.detail
    console.log(`Native player state changed: ${state}`)
    this.updatePlayerState(state, message)
  }

  // Handle native errors
  handleNativeError(event) {
    const { error } = event.detail
    console.error('Native player error:', error)
    this.updatePlayerState('error', error)
  }

  // Handle native participant events
  handleNativeParticipantEvent(event) {
    const { participant, action } = event.detail
    console.log(`Native participant ${action}:`, participant)
    this.updateParticipantList()
  }

  // Handle app going to background/foreground
  handleVisibilityChange() {
    const isVisible = !document.hidden
    
    if (this.isNativeApp) {
      // Native app background handling
      this.bridgeCall("setVideoVisibility", { visible: isVisible })
      
      if (!isVisible) {
        // App going to background - enable audio-only mode
        this.enableBackgroundAudio()
      } else {
        // App coming to foreground - restore video
        this.restoreVideoFromBackground()
      }
    } else {
      // Web player background handling
      this.handleWebBackgroundMode(isVisible)
    }
  }

  // Enable background audio mode
  async enableBackgroundAudio() {
    try {
      console.log("Enabling background audio mode...")
      
      if (this.isNativeApp) {
        // Tell native layer to enable background audio
        await this.bridgeCall("enableBackgroundAudio", {
          keepAudioActive: true,
          disableVideo: true
        })
      } else if (this.room) {
        // For web, just continue audio tracks
        const audioTracks = this.room.localParticipant.getTrackPublications()
          .filter(pub => pub.kind === 'audio')
        
        // Ensure audio tracks stay active
        audioTracks.forEach(track => {
          if (track.track) {
            track.track.enabled = true
          }
        })
      }
      
      this.updatePlayerState('background_audio', 'Audio continues in background')
      
    } catch (error) {
      console.error("Failed to enable background audio:", error)
    }
  }

  // Restore video from background
  async restoreVideoFromBackground() {
    try {
      console.log("Restoring video from background...")
      
      if (this.isNativeApp) {
        // Tell native layer to restore video
        await this.bridgeCall("restoreVideoFromBackground", {
          enableVideo: true,
          resumeAudio: true
        })
      } else if (this.room) {
        // For web, re-enable video tracks
        const videoTracks = this.room.localParticipant.getTrackPublications()
          .filter(pub => pub.kind === 'video')
        
        videoTracks.forEach(track => {
          if (track.track) {
            track.track.enabled = true
          }
        })
      }
      
      this.updatePlayerState('connected', 'Video restored')
      
    } catch (error) {
      console.error("Failed to restore video from background:", error)
    }
  }

  // Handle web background mode
  handleWebBackgroundMode(isVisible) {
    if (!this.room) return
    
    const videoElement = this.playerTarget.querySelector('video')
    
    if (!isVisible) {
      // Web app going to background
      console.log("Web app going to background - maintaining audio")
      
      if (videoElement) {
        // Pause video rendering but keep audio
        videoElement.style.visibility = 'hidden'
      }
      
      // Ensure audio tracks continue
      const audioTracks = Array.from(this.room.participants.values())
        .flatMap(participant => Array.from(participant.audioTracks.values()))
      
      audioTracks.forEach(trackPublication => {
        if (trackPublication.track && trackPublication.track.mediaStreamTrack) {
          trackPublication.track.mediaStreamTrack.enabled = true
        }
      })
      
      this.updatePlayerState('background_audio', 'Audio playing in background')
      
    } else {
      // Web app coming to foreground
      console.log("Web app coming to foreground - restoring video")
      
      if (videoElement) {
        videoElement.style.visibility = 'visible'
      }
      
      this.updatePlayerState('connected', 'Video restored')
    }
  }

  // Configure background audio permissions (for native)
  async configureBackgroundAudio() {
    if (!this.isNativeApp) return
    
    try {
      await this.bridgeCall("configureBackgroundAudio", {
        category: "playback", // AVAudioSession.Category.playback
        mode: "default",
        options: [
          "mixWithOthers",
          "allowBluetooth",
          "allowBluetoothA2DP"
        ],
        backgroundModes: ["audio"] // Required in Info.plist
      })
      
      console.log("Background audio configured successfully")
      
    } catch (error) {
      console.error("Failed to configure background audio:", error)
    }
  }

  // Update player state UI
  updatePlayerState(state, message = '') {
    const statusMap = {
      'initializing': { text: 'Initializing...', class: 'text-yellow-600' },
      'initialized': { text: 'Ready', class: 'text-blue-600' },
      'connecting': { text: 'Connecting...', class: 'text-yellow-600' },
      'connected': { text: 'Live', class: 'text-green-600' },
      'reconnecting': { text: 'Reconnecting...', class: 'text-yellow-600' },
      'disconnected': { text: 'Disconnected', class: 'text-gray-600' },
      'waiting_for_token': { text: 'Connecting...', class: 'text-yellow-600' },
      'starting_broadcast': { text: 'Starting Stream...', class: 'text-blue-600' },
      'background_audio': { text: 'Audio Only', class: 'text-blue-600' },
      'picture_in_picture': { text: 'Picture-in-Picture', class: 'text-blue-600' },
      'offline': { text: 'Stream Ended', class: 'text-gray-600' },
      'error': { text: `Error: ${message}`, class: 'text-red-600' }
    }
    
    const status = statusMap[state] || { text: state, class: 'text-gray-600' }
    
    if (this.hasStatusIndicatorTarget) {
      this.statusIndicatorTarget.textContent = status.text
      this.statusIndicatorTarget.className = `status-indicator ${status.class}`
    }
    
    // Update container classes
    this.element.setAttribute('data-player-state', state)
  }

  // Update participant list UI
  updateParticipantList() {
    // Implementation depends on UI requirements
    console.log('Updating participant list...')
  }

  // Bridge communication helpers
  async bridgeCall(method, params = {}) {
    if (!window.HotwireNative) {
      throw new Error("HotwireNative not available")
    }
    
    return new Promise((resolve, reject) => {
      const callId = Date.now().toString()
      
      // Listen for response
      const responseHandler = (event) => {
        if (event.detail.callId === callId) {
          window.removeEventListener("bridgeResponse", responseHandler)
          
          if (event.detail.success) {
            resolve(event.detail.result)
          } else {
            reject(new Error(event.detail.error))
          }
        }
      }
      
      window.addEventListener("bridgeResponse", responseHandler)
      
      // Send bridge message
      window.HotwireNative.postMessage({
        type: "videoPlayer",
        method: method,
        params: params,
        callId: callId
      })
      
      // Timeout after 10 seconds
      setTimeout(() => {
        window.removeEventListener("bridgeResponse", responseHandler)
        reject(new Error("Bridge call timeout"))
      }, 10000)
    })
  }

  addEventListener(eventName, handler) {
    window.addEventListener(eventName, handler)
    
    // Store for cleanup
    this.eventListeners = this.eventListeners || []
    this.eventListeners.push({ eventName, handler })
  }

  // Platform detection
  isHotwireNativeApp() {
    return typeof window.HotwireNative !== 'undefined' || 
           navigator.userAgent.includes('BackstagePass')
  }

  isMobileDevice() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  }

  // Cleanup
  cleanup() {
    console.log("Cleaning up video controller...")
    
    // Clean up adaptive bitrate monitoring
    if (this.qualityCheckInterval) {
      clearInterval(this.qualityCheckInterval)
      this.qualityCheckInterval = null
    }
    
    // Clean up event listeners
    if (this.eventListeners) {
      this.eventListeners.forEach(({ eventName, handler }) => {
        window.removeEventListener(eventName, handler)
      })
      this.eventListeners = []
    }
    
    // Disconnect from room
    if (this.room) {
      this.room.disconnect()
      this.room = null
    }
    
    // Notify native layer
    if (this.isNativeApp) {
      this.bridgeCall("cleanupVideoPlayer").catch(console.error)
    }
  }
}