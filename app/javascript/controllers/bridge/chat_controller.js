import { Controller } from "@hotwired/stimulus"
import { StreamChat } from "stream-chat"

// Mobile bridge controller for native chat functionality
// Connects to data-controller="bridge--chat" 
export default class extends Controller {
  static targets = ["messages", "input", "sendButton"]
  static values = { 
    apiKey: String,
    userId: String,
    userToken: String,
    channelId: String,
    channelType: String,
    userName: String,
    userImage: String,
    canModerate: Boolean,
    platform: String
  }

  connect() {
    this.isNativeApp = this.isHotwireNativeApp()
    this.isMobile = this.isMobileDevice()
    
    console.log(`Chat Bridge: Platform=${this.platformValue}, Native=${this.isNativeApp}, Mobile=${this.isMobile}`)
    
    if (this.isNativeApp) {
      this.initializeNativeChat()
    } else {
      this.initializeWebChat()
    }
  }

  disconnect() {
    this.cleanup()
  }

  // Native mobile integration
  async initializeNativeChat() {
    try {
      // Send configuration to native layer
      const chatConfig = {
        apiKey: this.apiKeyValue,
        userId: this.userIdValue,
        userToken: this.userTokenValue,
        channelId: this.channelIdValue,
        channelType: this.channelTypeValue,
        userName: this.userNameValue,
        userImage: this.userImageValue,
        canModerate: this.canModerateValue
      }

      // Use Hotwire Native bridge to initialize native chat
      if (window.HotwireNative) {
        await this.bridgeCall("initializeChat", chatConfig)
        
        // Listen for messages from native layer
        this.addEventListener("chatMessageReceived", this.handleNativeMessage.bind(this))
        this.addEventListener("chatUserJoined", this.handleNativeUserEvent.bind(this))
        this.addEventListener("chatUserLeft", this.handleNativeUserEvent.bind(this))
        this.addEventListener("chatModerationAction", this.handleNativeModerationAction.bind(this))
      } else {
        // Fallback to web implementation
        console.warn("HotwireNative not available, falling back to web chat")
        this.initializeWebChat()
      }

    } catch (error) {
      console.error("Failed to initialize native chat:", error)
      this.initializeWebChat() // Fallback
    }
  }

  // Web implementation (fallback or desktop)
  async initializeWebChat() {
    try {
      // Initialize GetStream.io client
      this.client = StreamChat.getInstance(this.apiKeyValue)
      
      // Connect user
      const user = {
        id: this.userIdValue,
        name: this.userNameValue,
        image: this.userImageValue
      }

      await this.client.connectUser(user, this.userTokenValue)
      
      // Get or create channel
      this.channel = this.client.channel(this.channelTypeValue, this.channelIdValue, {
        name: `Stream Chat - ${this.channelIdValue}`,
        members: [this.userIdValue]
      })

      await this.channel.watch()
      
      // Load existing messages
      this.loadMessages()
      
      // Listen for new messages
      this.channel.on('message.new', this.handleWebMessage.bind(this))
      this.channel.on('message.deleted', this.handleWebMessageDeleted.bind(this))
      
      this.updateConnectionState('connected')
      
    } catch (error) {
      console.error('Failed to initialize web chat:', error)
      this.updateConnectionState('error', error.message)
    }
  }

  // Send message (works for both native and web)
  async sendMessage(event) {
    event?.preventDefault()
    
    const messageText = this.inputTarget?.value?.trim()
    if (!messageText) return
    
    try {
      if (this.isNativeApp && window.HotwireNative) {
        // Send via native bridge
        await this.bridgeCall("sendMessage", { text: messageText })
      } else {
        // Send via web
        await this.channel.sendMessage({
          text: messageText,
          user_id: this.userIdValue
        })
      }
      
      // Clear input
      if (this.inputTarget) {
        this.inputTarget.value = ''
      }
      
    } catch (error) {
      console.error('Failed to send message:', error)
      this.showError('Failed to send message. Please try again.')
    }
  }

  // Native message handlers
  handleNativeMessage(event) {
    const { message } = event.detail
    this.renderMessage(message)
    this.scrollToBottom()
    
    // Optionally trigger web-side effects
    this.notifyWebLayer('messageReceived', message)
  }

  handleNativeUserEvent(event) {
    const { user, action } = event.detail
    console.log(`User ${action}:`, user)
    
    // Update UI if needed
    this.updateUserPresence(user, action)
  }

  handleNativeModerationAction(event) {
    const { action, target, result } = event.detail
    console.log(`Moderation ${action} on ${target}:`, result)
    
    this.showModerationFeedback(action, result)
  }

  // Web message handlers
  handleWebMessage(event) {
    this.renderMessage(event.message)
    this.scrollToBottom()
    
    // Notify native layer if available
    if (this.isNativeApp) {
      this.bridgeCall("onMessageReceived", { message: event.message })
    }
  }

  handleWebMessageDeleted(event) {
    const messageElement = this.messagesTarget?.querySelector(`[data-message-id="${event.message.id}"]`)
    if (messageElement) {
      messageElement.remove()
    }
    
    // Notify native layer
    if (this.isNativeApp) {
      this.bridgeCall("onMessageDeleted", { messageId: event.message.id })
    }
  }

  // Bridge helper methods
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
        type: "chat",
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

  // UI helpers
  renderMessage(message) {
    if (!this.messagesTarget) return
    
    const messageElement = document.createElement('div')
    messageElement.className = 'chat-message flex gap-3 p-3 hover:bg-gray-50'
    messageElement.setAttribute('data-message-id', message.id)
    
    const isOwnMessage = message.user.id === this.userIdValue
    const timestamp = new Date(message.created_at || message.timestamp || Date.now()).toLocaleTimeString()
    
    messageElement.innerHTML = `
      <div class="flex-shrink-0">
        <img src="${message.user.image || '/placeholder-avatar.png'}" 
             alt="${message.user.name}" 
             class="w-8 h-8 rounded-full">
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 mb-1">
          <span class="font-medium text-sm text-gray-900">${message.user.name}</span>
          <span class="text-xs text-gray-500">${timestamp}</span>
          ${isOwnMessage ? '<span class="text-xs text-blue-500">(You)</span>' : ''}
        </div>
        <div class="text-sm text-gray-700 break-words">
          ${this.escapeHtml(message.text)}
        </div>
      </div>
    `
    
    this.messagesTarget.appendChild(messageElement)
  }

  scrollToBottom() {
    if (this.messagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  updateConnectionState(state, message = '') {
    const chatContainer = this.element
    
    // Remove existing state classes
    chatContainer.classList.remove('chat-connecting', 'chat-connected', 'chat-error')
    
    // Add new state class
    chatContainer.classList.add(`chat-${state}`)
    
    // Update status indicator if it exists
    const statusElement = chatContainer.querySelector('.chat-status')
    if (statusElement) {
      switch (state) {
        case 'connecting':
          statusElement.textContent = 'Connecting to chat...'
          statusElement.className = 'chat-status text-yellow-600'
          break
        case 'connected':
          statusElement.textContent = 'Connected'
          statusElement.className = 'chat-status text-green-600'
          break
        case 'error':
          statusElement.textContent = `Error: ${message}`
          statusElement.className = 'chat-status text-red-600'
          break
      }
    }
  }

  showError(message) {
    // Show error to user
    if (window.alert) {
      alert(message)
    } else {
      console.error(message)
    }
  }

  showModerationFeedback(action, result) {
    const message = result.success ? 
      `${action} completed successfully` : 
      `${action} failed: ${result.error}`
    
    this.showError(message)
  }

  updateUserPresence(user, action) {
    // Update user list or presence indicators
    console.log(`User presence: ${user.name} ${action}`)
  }

  notifyWebLayer(event, data) {
    // Trigger custom events for web layer integration
    this.element.dispatchEvent(new CustomEvent(`chat:${event}`, {
      detail: data,
      bubbles: true
    }))
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  async loadMessages() {
    // For web implementation
    if (!this.channel) return
    
    try {
      const result = await this.channel.query({
        messages: { limit: 50 }
      })
      
      // Clear existing messages
      if (this.messagesTarget) {
        this.messagesTarget.innerHTML = ''
      }
      
      // Render messages
      result.messages.forEach(message => {
        this.renderMessage(message)
      })
      
      this.scrollToBottom()
      
    } catch (error) {
      console.error('Failed to load messages:', error)
    }
  }

  cleanup() {
    // Clean up event listeners
    if (this.eventListeners) {
      this.eventListeners.forEach(({ eventName, handler }) => {
        window.removeEventListener(eventName, handler)
      })
      this.eventListeners = []
    }
    
    // Clean up web chat
    if (this.channel) {
      this.channel.stopWatching()
    }
    if (this.client) {
      this.client.disconnectUser()
    }
    
    // Notify native layer
    if (this.isNativeApp) {
      this.bridgeCall("cleanupChat").catch(console.error)
    }
  }
}