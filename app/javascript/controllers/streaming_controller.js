import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    roomName: String, 
    experienceSlug: String, 
    spaceSlug: String, 
    canPublish: Boolean 
  }

  connect() {
    this.room = null
    this.connected = false
    
    // Auto-join the room if user has access
    if (this.canPublishValue || this.hasAccess()) {
      this.joinRoom()
    }
    
    // Poll for room info
    this.startRoomInfoPolling()
  }

  disconnect() {
    this.stopRoomInfoPolling()
    this.leaveRoom()
  }

  async joinRoom() {
    if (this.connected) return

    try {
      // Get access token from server
      const response = await fetch(`/${this.spaceSlugValue}/${this.experienceSlugValue}/video_token`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        throw new Error('Failed to get access token')
      }

      const data = await response.json()
      
      if (!data.success) {
        console.error('Failed to get video token:', data.message)
        return
      }

      // Initialize LiveKit room
      const { Room, RoomEvent, Track } = LiveKitClient
      
      this.room = new Room({
        adaptiveStream: true,
        dynacast: true,
        publishDefaults: {
          videoSimulcastLayers: [
            { resolution: { width: 1280, height: 720 }, encoding: { maxBitrate: 2000000 } },
            { resolution: { width: 640, height: 360 }, encoding: { maxBitrate: 500000 } },
            { resolution: { width: 320, height: 180 }, encoding: { maxBitrate: 150000 } }
          ]
        }
      })

      // Set up event listeners
      this.setupRoomEvents()

      // Connect to room
      await this.room.connect(data.room_url, data.access_token)
      this.connected = true
      
      console.log('Connected to LiveKit room:', this.roomNameValue)

    } catch (error) {
      console.error('Failed to join room:', error)
      this.showError('Failed to connect to stream')
    }
  }

  async leaveRoom() {
    if (this.room && this.connected) {
      await this.room.disconnect()
      this.room = null
      this.connected = false
    }
  }

  setupRoomEvents() {
    if (!this.room) return

    const { RoomEvent, Track } = LiveKitClient

    // Handle participant connections
    this.room.on(RoomEvent.ParticipantConnected, (participant) => {
      console.log('Participant connected:', participant.identity)
      this.updateParticipantCount()
    })

    this.room.on(RoomEvent.ParticipantDisconnected, (participant) => {
      console.log('Participant disconnected:', participant.identity)
      this.updateParticipantCount()
    })

    // Handle track subscriptions
    this.room.on(RoomEvent.TrackSubscribed, (track, publication, participant) => {
      console.log('Track subscribed:', track.kind, participant.identity)
      
      if (track.kind === Track.Kind.Video || track.kind === Track.Kind.Audio) {
        const element = track.attach()
        
        if (track.kind === Track.Kind.Video) {
          element.style.width = '100%'
          element.style.height = '100%'
          element.style.objectFit = 'contain'
        }
        
        this.element.appendChild(element)
      }
    })

    this.room.on(RoomEvent.TrackUnsubscribed, (track, publication, participant) => {
      console.log('Track unsubscribed:', track.kind, participant.identity)
      track.detach()
    })

    // Handle room disconnection
    this.room.on(RoomEvent.Disconnected, (reason) => {
      console.log('Disconnected from room:', reason)
      this.connected = false
      this.clearVideoElements()
    })

    // Handle connection quality
    this.room.on(RoomEvent.ConnectionQualityChanged, (quality, participant) => {
      console.log('Connection quality:', quality, participant?.identity)
    })
  }

  async startStream() {
    if (!this.canPublishValue) {
      this.showError('Not authorized to broadcast')
      return
    }

    try {
      const response = await fetch(`/account/streams/${this.getStreamId()}/start_stream`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })

      const data = await response.json()
      
      if (data.success) {
        console.log('Stream started successfully')
        await this.enableCameraAndMicrophone()
        location.reload() // Refresh to update UI
      } else {
        this.showError(data.message || 'Failed to start stream')
      }
    } catch (error) {
      console.error('Failed to start stream:', error)
      this.showError('Failed to start stream')
    }
  }

  async stopStream() {
    if (!this.canPublishValue) {
      this.showError('Not authorized to control stream')
      return
    }

    try {
      const response = await fetch(`/account/streams/${this.getStreamId()}/stop_stream`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })

      const data = await response.json()
      
      if (data.success) {
        console.log('Stream stopped successfully')
        await this.disableMediaTracks()
        location.reload() // Refresh to update UI
      } else {
        this.showError(data.message || 'Failed to stop stream')
      }
    } catch (error) {
      console.error('Failed to stop stream:', error)
      this.showError('Failed to stop stream')
    }
  }

  async enableCameraAndMicrophone() {
    if (!this.room || !this.connected) return

    try {
      // Enable camera and microphone
      await this.room.localParticipant.enableCameraAndMicrophone()
      console.log('Camera and microphone enabled')
    } catch (error) {
      console.error('Failed to enable camera/microphone:', error)
      this.showError('Failed to access camera/microphone')
    }
  }

  async disableMediaTracks() {
    if (!this.room || !this.connected) return

    try {
      // Disable all local tracks
      this.room.localParticipant.videoTracks.forEach((publication) => {
        publication.track?.stop()
        this.room.localParticipant.unpublishTrack(publication.track)
      })
      
      this.room.localParticipant.audioTracks.forEach((publication) => {
        publication.track?.stop()
        this.room.localParticipant.unpublishTrack(publication.track)
      })
    } catch (error) {
      console.error('Failed to disable media tracks:', error)
    }
  }

  startRoomInfoPolling() {
    this.roomInfoInterval = setInterval(() => {
      this.updateRoomInfo()
    }, 5000) // Update every 5 seconds
  }

  stopRoomInfoPolling() {
    if (this.roomInfoInterval) {
      clearInterval(this.roomInfoInterval)
    }
  }

  async updateRoomInfo() {
    try {
      const response = await fetch(`/${this.spaceSlugValue}/${this.experienceSlugValue}/stream_info`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateParticipantCount(data.participant_count)
        this.updateMaxViewers(data.stream?.max_viewers)
      }
    } catch (error) {
      console.error('Failed to update room info:', error)
    }
  }

  updateParticipantCount(count = null) {
    const countElement = document.getElementById('participant-count')
    if (countElement) {
      const actualCount = count !== null ? count : (this.room?.participants?.size || 0)
      countElement.textContent = actualCount
    }
  }

  updateMaxViewers(maxViewers) {
    const maxViewersElement = document.getElementById('max-viewers')
    if (maxViewersElement && maxViewers) {
      maxViewersElement.textContent = maxViewers
    }
  }

  clearVideoElements() {
    // Remove all video/audio elements
    const mediaElements = this.element.querySelectorAll('video, audio')
    mediaElements.forEach(element => element.remove())
  }

  getStreamId() {
    // Extract stream ID from URL or data attribute
    const pathParts = window.location.pathname.split('/')
    const streamIndex = pathParts.indexOf('streams')
    return streamIndex !== -1 && pathParts[streamIndex + 1] ? pathParts[streamIndex + 1] : null
  }

  hasAccess() {
    // Check if user is signed in and potentially has access
    return document.querySelector('meta[name="user-signed-in"]')?.content === 'true'
  }

  showError(message) {
    // Simple error display - could be enhanced with better UI
    console.error(message)
    
    // Show in video container
    const errorDiv = document.createElement('div')
    errorDiv.className = 'absolute inset-0 flex items-center justify-center bg-black bg-opacity-50 text-white'
    errorDiv.innerHTML = `
      <div class="text-center">
        <p class="text-lg font-medium">${message}</p>
        <button onclick="this.parentElement.parentElement.remove()" 
                class="mt-4 px-4 py-2 bg-red-600 hover:bg-red-700 rounded text-sm">
          Close
        </button>
      </div>
    `
    
    this.element.appendChild(errorDiv)
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      errorDiv.remove()
    }, 5000)
  }
}