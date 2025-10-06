import { Controller } from "@hotwired/stimulus"

/**
 * Stream Viewer Controller
 * Handles the viewer experience for live streams with chat integration
 */
export default class extends Controller {
  static values = { 
    streamId: Number,
    canView: Boolean,
    accessible: Boolean
  }

  static targets = [
    "video",
    "loading",
    "error", 
    "controls",
    "chatSidebar",
    "mobileChat",
    "chatMessages",
    "mobileChatMessages",
    "chatInput",
    "mobileChatInput",
    "viewerCount",
    "connectionStatus"
  ]

  connect() {
    console.log('Stream viewer connecting...')
    
    this.room = null
    this.chat = null
    this.chatChannel = null
    this.connected = false
    this.chatConnected = false
    this.controlsTimeout = null
    this.isFullscreen = false
    
    // Load stream configuration from data
    this.loadStreamConfig()
    
    if (this.accessibleValue && this.canViewValue) {
      this.initializeStream()
    } else {
      this.showAccessDenied()
    }
    
    this.bindEvents()
  }

  disconnect() {
    this.cleanup()
  }

  loadStreamConfig() {
    const configElement = document.getElementById('stream-data')
    if (configElement) {
      try {
        this.config = JSON.parse(configElement.textContent)
        console.log('Stream config loaded:', this.config)
      } catch (error) {
        console.error('Failed to load stream config:', error)
        this.config = {}
      }
    } else {
      this.config = {}
    }
  }

  async initializeStream() {
    try {
      this.showLoading('Connecting to stream...')
      
      // Initialize video connection
      await this.connectToVideo()
      
      // Initialize chat
      await this.connectToChat()
      
      // Start periodic updates
      this.startPeriodicUpdates()
      
      this.hideLoading()
      this.showConnectionStatus('Connected')
      
    } catch (error) {
      console.error('Stream initialization failed:', error)
      this.showError('Failed to connect to stream', error.message)
    }
  }

  async connectToVideo() {
    if (typeof LiveKitClient === 'undefined') {
      throw new Error('LiveKit client not loaded')
    }

    try {
      // Get video token from server
      const response = await fetch(this.config.endpoints.video_token, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`Failed to get video token: ${response.status}`)
      }

      const tokenData = await response.json()
      if (!tokenData.success) {
        throw new Error(tokenData.message || 'Access denied')
      }

      // Create LiveKit room with simulcast enabled
      const { Room, RoomEvent, Track, VideoPresets } = LiveKitClient

      // Check if this user can broadcast
      const canBroadcast = this.config.permissions?.can_broadcast || false

      this.room = new Room({
        adaptiveStream: true,
        dynacast: true,
        // Enable simulcast for broadcasters
        publishDefaults: {
          simulcast: canBroadcast,
          videoSimulcastLayers: canBroadcast ? [
            VideoPresets.h720,
            VideoPresets.h360,
            VideoPresets.h180
          ] : []
        },
        // Optimized video capture
        videoCaptureDefaults: {
          resolution: VideoPresets.h720.resolution
        }
      })

      this.setupVideoEvents()

      // Connect to room
      await this.room.connect(tokenData.room_url, tokenData.access_token)
      this.connected = true

      console.log('Connected to LiveKit room:', tokenData.room_name)

      // Dispatch event for other controllers (e.g., broadcaster-controls)
      this.element.dispatchEvent(new CustomEvent('livekit:connected', {
        detail: { room: this.room, localParticipant: this.room.localParticipant }
      }))
      
    } catch (error) {
      console.error('Video connection failed:', error)
      throw error
    }
  }

  setupVideoEvents() {
    const { RoomEvent, Track } = LiveKitClient

    // Handle track subscribed (when broadcaster starts streaming)
    this.room.on(RoomEvent.TrackSubscribed, (track, publication, participant) => {
      console.log('Track subscribed:', track.kind, participant.identity)
      
      if (track.kind === Track.Kind.Video) {
        const videoElement = track.attach()
        videoElement.style.width = '100%'
        videoElement.style.height = '100%'
        videoElement.style.objectFit = 'contain'
        videoElement.style.backgroundColor = 'black'
        
        // Clear loading and add video
        if (this.hasVideoTarget) {
          this.videoTarget.innerHTML = ''
          this.videoTarget.appendChild(videoElement)
        }
        
        this.hideLoading()
      }
      
      if (track.kind === Track.Kind.Audio) {
        const audioElement = track.attach()
        if (this.hasVideoTarget) {
          this.videoTarget.appendChild(audioElement)
        }
      }
    })

    // Handle track unsubscribed
    this.room.on(RoomEvent.TrackUnsubscribed, (track) => {
      track.detach()
    })

    // Handle participant events
    this.room.on(RoomEvent.ParticipantConnected, (participant) => {
      console.log('Participant connected:', participant.identity)
      this.updateViewerCount()
    })

    this.room.on(RoomEvent.ParticipantDisconnected, (participant) => {
      console.log('Participant disconnected:', participant.identity)
      this.updateViewerCount()
    })

    // Handle disconnection
    this.room.on(RoomEvent.Disconnected, (reason) => {
      console.log('Disconnected from room:', reason)
      this.connected = false
      this.showError('Connection lost', 'The stream connection was interrupted')
    })

    // Handle connection quality
    this.room.on(RoomEvent.ConnectionQualityChanged, (quality, participant) => {
      this.updateConnectionQuality(quality)
    })
  }

  async connectToChat() {
    if (typeof StreamChat === 'undefined') {
      console.warn('StreamChat SDK not loaded')
      return
    }

    if (!this.config.chat_room) {
      console.warn('No chat room configured')
      return
    }

    try {
      // Get chat token
      const response = await fetch(this.config.endpoints.chat_token, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`Failed to get chat token: ${response.status}`)
      }

      const tokenData = await response.json()
      if (!tokenData.success) {
        throw new Error(tokenData.message || 'Chat access denied')
      }

      if (!tokenData.api_key) {
        throw new Error('API key not provided by server')
      }

      // Initialize StreamChat with the correct constructor
      this.chat = new StreamChat(tokenData.api_key)

      // Connect user
      await this.chat.connectUser({
        id: tokenData.user_id,
        name: tokenData.user_name
      }, tokenData.token)

      // Get channel
      this.chatChannel = this.chat.channel('livestream', tokenData.chat_room_id)
      await this.chatChannel.watch()

      this.setupChatEvents()
      this.enableChatInput()
      this.chatConnected = true

      console.log('✅ Connected to chat:', tokenData.chat_room_id)

    } catch (error) {
      console.error('❌ Chat connection failed:', error)
      this.disableChatInput()
    }
  }

  setupChatEvents() {
    if (!this.chatChannel) return

    // Handle new messages
    this.chatChannel.on('message.new', (event) => {
      this.addChatMessage(event.message)
    })

    // Handle member events
    this.chatChannel.on('member.added', (event) => {
      console.log('User joined chat:', event.member.user.name)
    })

    this.chatChannel.on('member.removed', (event) => {
      console.log('User left chat:', event.user.name)
    })
  }

  bindEvents() {
    // Mobile chat toggle
    this.element.addEventListener('click', (e) => {
      if (e.target.id === 'chat-toggle') {
        this.toggleMobileChat()
      }
    })

    // Fullscreen toggle
    this.element.addEventListener('click', (e) => {
      if (e.target.id === 'fullscreen-toggle') {
        this.toggleFullscreen()
      }
    })

    // Send button handlers
    this.element.addEventListener('click', (e) => {
      if (e.target.id === 'send-message' || e.target.closest('#send-message')) {
        e.preventDefault()
        if (this.hasChatInputTarget) {
          this.sendMessage(this.chatInputTarget.value)
          this.chatInputTarget.value = ''
        }
      }

      if (e.target.id === 'mobile-send-message' || e.target.closest('#mobile-send-message')) {
        e.preventDefault()
        if (this.hasMobileChatInputTarget) {
          this.sendMessage(this.mobileChatInputTarget.value)
          this.mobileChatInputTarget.value = ''
        }
      }
    })

    // Chat input handling
    if (this.hasChatInputTarget) {
      this.chatInputTarget.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          this.sendMessage(this.chatInputTarget.value)
          this.chatInputTarget.value = ''
        }
      })
    }

    if (this.hasMobileChatInputTarget) {
      this.mobileChatInputTarget.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          this.sendMessage(this.mobileChatInputTarget.value)
          this.mobileChatInputTarget.value = ''
        }
      })
    }

    // Auto-hide controls on fullscreen
    this.setupControlsAutoHide()

    // Handle fullscreen changes
    document.addEventListener('fullscreenchange', () => {
      this.isFullscreen = !!document.fullscreenElement
    })
  }

  setupControlsAutoHide() {
    if (!this.hasControlsTarget) return

    const showControls = () => {
      this.controlsTarget.style.opacity = '1'
      clearTimeout(this.controlsTimeout)
      this.controlsTimeout = setTimeout(() => {
        if (this.isFullscreen) {
          this.controlsTarget.style.opacity = '0'
        }
      }, 3000)
    }

    this.element.addEventListener('mousemove', showControls)
    this.element.addEventListener('touchstart', showControls)
    
    this.controlsTarget.addEventListener('mouseenter', () => {
      clearTimeout(this.controlsTimeout)
    })
  }

  async sendMessage(text) {
    if (!this.chatChannel || !text.trim()) return

    try {
      await this.chatChannel.sendMessage({
        text: text.trim()
      })
    } catch (error) {
      console.error('Failed to send message:', error)
    }
  }

  addChatMessage(message) {
    const messageElement = this.createMessageElement(message)
    
    // Add to desktop chat
    if (this.hasChatMessagesTarget) {
      this.chatMessagesTarget.appendChild(messageElement.cloneNode(true))
      this.chatMessagesTarget.scrollTop = this.chatMessagesTarget.scrollHeight
    }

    // Add to mobile chat
    if (this.hasMobileChatMessagesTarget) {
      this.mobileChatMessagesTarget.appendChild(messageElement)
      this.mobileChatMessagesTarget.scrollTop = this.mobileChatMessagesTarget.scrollHeight
    }
  }

  createMessageElement(message) {
    const div = document.createElement('div')
    div.className = 'flex items-start space-x-2 mb-2'
    
    const timestamp = new Date(message.created_at).toLocaleTimeString([], {
      hour: '2-digit', minute: '2-digit'
    })

    div.innerHTML = `
      <div class="flex-1 min-w-0">
        <div class="flex items-center space-x-2">
          <span class="text-sm font-medium text-white">${this.escapeHtml(message.user.name || message.user.id)}</span>
          <span class="text-xs text-gray-400">${timestamp}</span>
        </div>
        <p class="text-sm text-gray-300 break-words">${this.escapeHtml(message.text)}</p>
      </div>
    `
    
    return div
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  toggleMobileChat() {
    if (this.hasMobileChatTarget) {
      this.mobileChatTarget.classList.toggle('translate-y-full')
    }
  }

  toggleFullscreen() {
    if (this.isFullscreen) {
      document.exitFullscreen()
    } else {
      this.element.requestFullscreen()
    }
  }

  enableChatInput() {
    if (this.hasChatInputTarget) {
      this.chatInputTarget.disabled = false
      this.chatInputTarget.placeholder = 'Type a message...'
    }
    if (this.hasMobileChatInputTarget) {
      this.mobileChatInputTarget.disabled = false
      this.mobileChatInputTarget.placeholder = 'Type a message...'
    }

    // Enable send buttons
    const sendButtons = document.querySelectorAll('#send-message, #mobile-send-message')
    sendButtons.forEach(btn => btn.disabled = false)
  }

  disableChatInput() {
    if (this.hasChatInputTarget) {
      this.chatInputTarget.disabled = true
      this.chatInputTarget.placeholder = 'Chat unavailable'
    }
    if (this.hasMobileChatInputTarget) {
      this.mobileChatInputTarget.disabled = true
      this.mobileChatInputTarget.placeholder = 'Chat unavailable'
    }

    // Disable send buttons
    const sendButtons = document.querySelectorAll('#send-message, #mobile-send-message')
    sendButtons.forEach(btn => btn.disabled = true)
  }

  updateViewerCount() {
    if (this.hasViewerCountTarget && this.room) {
      const count = this.room.participants.size
      this.viewerCountTarget.textContent = `${count} viewer${count !== 1 ? 's' : ''}`
    }
  }

  updateConnectionQuality(quality) {
    if (this.hasConnectionStatusTarget) {
      const status = quality === 'excellent' ? 'Excellent' : 
                   quality === 'good' ? 'Good' :
                   quality === 'poor' ? 'Poor' : 'Unknown'
      
      this.connectionStatusTarget.textContent = status
      this.connectionStatusTarget.className = `text-sm ${
        quality === 'excellent' ? 'text-green-400' :
        quality === 'good' ? 'text-yellow-400' :
        'text-red-400'
      }`
    }
  }

  startPeriodicUpdates() {
    // Update viewer count every 30 seconds
    setInterval(() => {
      this.updateViewerCount()
    }, 30000)

    // Check stream status every 60 seconds
    setInterval(() => {
      this.checkStreamStatus()
    }, 60000)
  }

  async checkStreamStatus() {
    try {
      const response = await fetch(this.config.endpoints.stream_info)
      if (response.ok) {
        const data = await response.json()
        if (data.success && data.stream.status !== this.config.stream.status) {
          console.log('Stream status changed:', data.stream.status)
          // Handle status changes if needed
        }
      }
    } catch (error) {
      console.error('Failed to check stream status:', error)
    }
  }

  showLoading(message = 'Loading...') {
    if (this.hasLoadingTarget) {
      this.loadingTarget.innerHTML = `
        <div class="text-center text-white">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto mb-4"></div>
          <p class="text-lg">${message}</p>
        </div>
      `
      this.loadingTarget.style.display = 'flex'
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'none'
    }
  }

  showError(title, message) {
    if (this.hasErrorTarget) {
      this.errorTarget.innerHTML = `
        <div class="text-center text-white max-w-md mx-auto px-6">
          <svg class="mx-auto h-16 w-16 text-red-500 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <h3 class="text-xl font-semibold mb-2">${title}</h3>
          <p class="text-gray-300 mb-4">${message}</p>
          <button onclick="location.reload()" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-lg font-medium">
            Retry
          </button>
        </div>
      `
      this.errorTarget.style.display = 'flex'
    }
    this.hideLoading()
  }

  showAccessDenied() {
    this.showError(
      'Access Required',
      'You need an active access pass to view this stream'
    )
  }

  showConnectionStatus(status) {
    if (this.hasConnectionStatusTarget) {
      this.connectionStatusTarget.textContent = status
    }
  }

  // Public methods for broadcaster-controls controller
  getRoom() {
    return this.room
  }

  getLocalParticipant() {
    return this.room?.localParticipant
  }

  isConnected() {
    return this.connected && this.room
  }

  cleanup() {
    // Disconnect from video
    if (this.room && this.connected) {
      this.room.disconnect()
    }

    // Disconnect from chat
    if (this.chat && this.chatConnected) {
      this.chat.disconnectUser()
    }

    // Clear timeouts
    if (this.controlsTimeout) {
      clearTimeout(this.controlsTimeout)
    }
  }
}