/**
 * LiveKit Streaming Viewer
 * Handles video streaming and chat functionality for stream viewing
 */
class LiveKitStreamingViewer {
  constructor() {
    this.streamData = this.loadStreamData();
    this.livekitRoom = null;
    this.streamChat = null;
    this.chatChannel = null;
    this.chatConnected = false;
    this.videoConnected = false;
    this.isFullscreen = false;
    this.controlsTimer = null;
    
    if (this.streamData && this.streamData.stream.accessible) {
      this.initializeComponents();
    }
    
    this.bindEvents();
  }

  loadStreamData() {
    const scriptTag = document.getElementById('stream-data');
    if (scriptTag) {
      try {
        return JSON.parse(scriptTag.textContent);
      } catch (e) {
        console.error('Failed to parse stream data:', e);
      }
    }
    return null;
  }

  async initializeComponents() {
    try {
      // Initialize video player if stream is accessible
      if (this.streamData.stream.accessible && this.streamData.permissions.can_view) {
        await this.initializeVideo();
      }

      // Initialize chat
      await this.initializeChat();
      
      // Start periodic updates
      this.startPeriodicUpdates();
      
    } catch (error) {
      console.error('Failed to initialize components:', error);
      this.showError('Failed to load stream components');
    }
  }

  async initializeVideo() {
    if (typeof LiveKit === 'undefined') {
      throw new Error('LiveKit SDK not loaded');
    }

    try {
      // Get video token from server
      const tokenResponse = await fetch(this.streamData.endpoints.video_token, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });

      if (!tokenResponse.ok) {
        throw new Error(`Failed to get video token: ${tokenResponse.status}`);
      }

      const tokenData = await tokenResponse.json();
      if (!tokenData.success) {
        throw new Error(tokenData.message || 'Failed to get video token');
      }

      // Create LiveKit room
      this.livekitRoom = new LiveKit.Room({
        adaptiveStream: true,
        dynacast: true,
        videoCaptureDefaults: {
          resolution: LiveKit.VideoPresets.h720.resolution,
        },
      });

      // Set up event listeners
      this.setupVideoEvents();

      // Connect to room
      await this.livekitRoom.connect(tokenData.room_url, tokenData.access_token);
      
      this.videoConnected = true;
      this.hideVideoLoading();
      
      console.log('Connected to LiveKit room:', tokenData.room_name);
      
    } catch (error) {
      console.error('Video initialization failed:', error);
      this.showVideoError('Failed to connect to video stream');
    }
  }

  setupVideoEvents() {
    const videoContainer = document.getElementById('livekit-video');
    
    // Handle track subscribed (remote participants)
    this.livekitRoom.on(LiveKit.RoomEvent.TrackSubscribed, (track, publication, participant) => {
      if (track.kind === LiveKit.Track.Kind.Video) {
        const element = track.attach();
        element.style.width = '100%';
        element.style.height = '100%';
        element.style.objectFit = 'contain';
        videoContainer.appendChild(element);
      }
    });

    // Handle track unsubscribed
    this.livekitRoom.on(LiveKit.RoomEvent.TrackUnsubscribed, (track, publication, participant) => {
      track.detach();
    });

    // Handle participant connected
    this.livekitRoom.on(LiveKit.RoomEvent.ParticipantConnected, (participant) => {
      console.log('Participant connected:', participant.identity);
      this.updateViewerCount();
    });

    // Handle participant disconnected
    this.livekitRoom.on(LiveKit.RoomEvent.ParticipantDisconnected, (participant) => {
      console.log('Participant disconnected:', participant.identity);
      this.updateViewerCount();
    });

    // Handle room disconnected
    this.livekitRoom.on(LiveKit.RoomEvent.Disconnected, () => {
      console.log('Disconnected from room');
      this.videoConnected = false;
      this.showVideoError('Connection lost');
    });

    // Handle connection quality
    this.livekitRoom.on(LiveKit.RoomEvent.ConnectionQualityChanged, (quality, participant) => {
      console.log('Connection quality:', quality);
    });
  }

  async initializeChat() {
    if (typeof StreamChat === 'undefined') {
      console.warn('StreamChat SDK not loaded, chat disabled');
      return;
    }

    if (!this.streamData.chat_room) {
      console.warn('No chat room available');
      return;
    }

    try {
      // Get chat token from server
      const tokenResponse = await fetch(this.streamData.endpoints.chat_token, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });

      if (!tokenResponse.ok) {
        throw new Error(`Failed to get chat token: ${tokenResponse.status}`);
      }

      const tokenData = await tokenResponse.json();
      if (!tokenData.success) {
        throw new Error(tokenData.message || 'Failed to get chat token');
      }

      // Initialize Stream Chat
      this.streamChat = StreamChat.getInstance(tokenData.api_key || 'demo');
      
      // Connect user
      await this.streamChat.connectUser(
        {
          id: tokenData.user_id,
          name: tokenData.user_name,
        },
        tokenData.token
      );

      // Get chat channel
      this.chatChannel = this.streamChat.channel('livestream', this.streamData.chat_room.channel_id);
      
      // Watch channel
      await this.chatChannel.watch();

      // Set up chat event listeners
      this.setupChatEvents();

      this.chatConnected = true;
      this.enableChatInput();
      
      console.log('Connected to chat channel:', this.streamData.chat_room.channel_id);
      
    } catch (error) {
      console.error('Chat initialization failed:', error);
      this.disableChatInput();
    }
  }

  setupChatEvents() {
    // Handle new messages
    this.chatChannel.on('message.new', (event) => {
      this.appendChatMessage(event.message);
    });

    // Handle user added to channel
    this.chatChannel.on('member.added', (event) => {
      console.log('User joined chat:', event.member.user.name);
    });

    // Handle user removed from channel
    this.chatChannel.on('member.removed', (event) => {
      console.log('User left chat:', event.user.name);
    });
  }

  bindEvents() {
    // Chat toggle (mobile)
    const chatToggle = document.getElementById('chat-toggle');
    if (chatToggle) {
      chatToggle.addEventListener('click', () => this.toggleMobileChat());
    }

    // Close mobile chat
    const closeMobileChat = document.getElementById('close-mobile-chat');
    if (closeMobileChat) {
      closeMobileChat.addEventListener('click', () => this.hideMobileChat());
    }

    // Close desktop chat
    const closeChat = document.getElementById('close-chat');
    if (closeChat) {
      closeChat.addEventListener('click', () => this.hideChatSidebar());
    }

    // Fullscreen toggle
    const fullscreenToggle = document.getElementById('fullscreen-toggle');
    if (fullscreenToggle) {
      fullscreenToggle.addEventListener('click', () => this.toggleFullscreen());
    }

    // Chat input handlers
    this.bindChatInputs();

    // Auto-hide controls
    this.bindControlsAutoHide();

    // Handle fullscreen changes
    document.addEventListener('fullscreenchange', () => {
      this.isFullscreen = !!document.fullscreenElement;
    });

    // Handle visibility change
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        // Tab/app is hidden
        console.log('App hidden');
      } else {
        // Tab/app is visible
        console.log('App visible');
        this.updateViewerCount();
      }
    });
  }

  bindChatInputs() {
    // Desktop chat input
    const chatInput = document.getElementById('chat-input');
    const sendButton = document.getElementById('send-message');
    
    if (chatInput && sendButton) {
      chatInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          this.sendChatMessage(chatInput.value);
          chatInput.value = '';
        }
      });

      sendButton.addEventListener('click', () => {
        this.sendChatMessage(chatInput.value);
        chatInput.value = '';
      });
    }

    // Mobile chat input
    const mobileChatInput = document.getElementById('mobile-chat-input');
    const mobileSendButton = document.getElementById('mobile-send-message');
    
    if (mobileChatInput && mobileSendButton) {
      mobileChatInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          this.sendChatMessage(mobileChatInput.value);
          mobileChatInput.value = '';
        }
      });

      mobileSendButton.addEventListener('click', () => {
        this.sendChatMessage(mobileChatInput.value);
        mobileChatInput.value = '';
      });
    }
  }

  bindControlsAutoHide() {
    const streamControls = document.getElementById('stream-controls');
    const videoContainer = document.getElementById('video-container');
    
    if (!streamControls || !videoContainer) return;

    const showControls = () => {
      streamControls.style.opacity = '1';
      clearTimeout(this.controlsTimer);
      this.controlsTimer = setTimeout(() => {
        if (this.isFullscreen) {
          streamControls.style.opacity = '0';
        }
      }, 3000);
    };

    const hideControls = () => {
      if (this.isFullscreen) {
        streamControls.style.opacity = '0';
      }
    };

    videoContainer.addEventListener('mousemove', showControls);
    videoContainer.addEventListener('touchstart', showControls);
    streamControls.addEventListener('mouseenter', () => {
      clearTimeout(this.controlsTimer);
    });
    streamControls.addEventListener('mouseleave', hideControls);
  }

  async sendChatMessage(message) {
    if (!this.chatChannel || !message.trim()) return;

    try {
      await this.chatChannel.sendMessage({
        text: message.trim()
      });
    } catch (error) {
      console.error('Failed to send message:', error);
    }
  }

  appendChatMessage(message) {
    const messageElement = this.createMessageElement(message);
    
    // Add to desktop chat
    const chatMessages = document.getElementById('chat-messages');
    if (chatMessages) {
      chatMessages.appendChild(messageElement.cloneNode(true));
      chatMessages.scrollTop = chatMessages.scrollHeight;
    }

    // Add to mobile chat
    const mobileChatMessages = document.getElementById('mobile-chat-messages');
    if (mobileChatMessages) {
      mobileChatMessages.appendChild(messageElement);
      mobileChatMessages.scrollTop = mobileChatMessages.scrollHeight;
    }
  }

  createMessageElement(message) {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'flex items-start space-x-2';

    const timestamp = new Date(message.created_at).toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit'
    });

    messageDiv.innerHTML = `
      <div class="flex-1 min-w-0">
        <div class="flex items-center space-x-2">
          <span class="text-sm font-medium text-white">${this.escapeHtml(message.user.name || message.user.id)}</span>
          <span class="text-xs text-gray-400">${timestamp}</span>
        </div>
        <p class="text-sm text-gray-300 break-words">${this.escapeHtml(message.text)}</p>
      </div>
    `;

    return messageDiv;
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  toggleMobileChat() {
    const mobileChat = document.getElementById('mobile-chat');
    if (mobileChat) {
      mobileChat.classList.toggle('translate-y-full');
    }
  }

  hideMobileChat() {
    const mobileChat = document.getElementById('mobile-chat');
    if (mobileChat) {
      mobileChat.classList.add('translate-y-full');
    }
  }

  hideChatSidebar() {
    const chatSidebar = document.getElementById('chat-sidebar');
    if (chatSidebar) {
      chatSidebar.classList.add('hidden');
    }
  }

  toggleFullscreen() {
    if (this.isFullscreen) {
      document.exitFullscreen();
    } else {
      document.documentElement.requestFullscreen();
    }
  }

  enableChatInput() {
    const chatInput = document.getElementById('chat-input');
    const sendButton = document.getElementById('send-message');
    const mobileChatInput = document.getElementById('mobile-chat-input');
    const mobileSendButton = document.getElementById('mobile-send-message');

    if (chatInput) {
      chatInput.disabled = false;
      chatInput.placeholder = 'Type a message...';
    }
    if (sendButton) sendButton.disabled = false;
    if (mobileChatInput) {
      mobileChatInput.disabled = false;
      mobileChatInput.placeholder = 'Type a message...';
    }
    if (mobileSendButton) mobileSendButton.disabled = false;
  }

  disableChatInput() {
    const chatInput = document.getElementById('chat-input');
    const sendButton = document.getElementById('send-message');
    const mobileChatInput = document.getElementById('mobile-chat-input');
    const mobileSendButton = document.getElementById('mobile-send-message');

    if (chatInput) {
      chatInput.disabled = true;
      chatInput.placeholder = 'Chat unavailable';
    }
    if (sendButton) sendButton.disabled = true;
    if (mobileChatInput) {
      mobileChatInput.disabled = true;
      mobileChatInput.placeholder = 'Chat unavailable';
    }
    if (mobileSendButton) mobileSendButton.disabled = true;
  }

  hideVideoLoading() {
    const loadingElement = document.getElementById('video-loading');
    if (loadingElement) {
      loadingElement.style.display = 'none';
    }
  }

  showVideoError(message) {
    const loadingElement = document.getElementById('video-loading');
    if (loadingElement) {
      loadingElement.innerHTML = `
        <div class="text-center text-white">
          <svg class="mx-auto h-12 w-12 text-red-500 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <p class="text-lg mb-2">Video Error</p>
          <p class="text-sm text-gray-300">${message}</p>
          <button onclick="location.reload()" class="mt-4 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg">
            Retry
          </button>
        </div>
      `;
    }
  }

  showError(message) {
    console.error('Stream error:', message);
    // Could add toast notification here
  }

  async updateViewerCount() {
    if (!this.livekitRoom) return;

    try {
      const participants = this.livekitRoom.participants;
      const count = participants.size;
      
      const viewerCountElement = document.getElementById('viewer-count');
      if (viewerCountElement) {
        viewerCountElement.textContent = `${count} viewer${count !== 1 ? 's' : ''}`;
      }
    } catch (error) {
      console.error('Failed to update viewer count:', error);
    }
  }

  startPeriodicUpdates() {
    // Update viewer count every 30 seconds
    setInterval(() => {
      this.updateViewerCount();
    }, 30000);

    // Check stream status every 60 seconds
    setInterval(async () => {
      try {
        const response = await fetch(this.streamData.endpoints.stream_info);
        if (response.ok) {
          const data = await response.json();
          if (data.success) {
            // Handle stream status changes
            if (data.stream.status !== this.streamData.stream.status) {
              console.log('Stream status changed:', data.stream.status);
              // Could trigger UI updates here
            }
          }
        }
      } catch (error) {
        console.error('Failed to check stream status:', error);
      }
    }, 60000);
  }

  // Cleanup when page is unloaded
  cleanup() {
    if (this.livekitRoom) {
      this.livekitRoom.disconnect();
    }
    if (this.streamChat) {
      this.streamChat.disconnectUser();
    }
  }
}

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  if (window.livekitViewer) {
    window.livekitViewer.cleanup();
  }
});

// Export for global access
window.LiveKitStreamingViewer = LiveKitStreamingViewer;