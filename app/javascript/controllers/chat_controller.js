import { Controller } from "@hotwired/stimulus"
import { StreamChat } from "stream-chat"

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = ["messages", "input", "sendButton", "userList", "moderationPanel"]
  static values = { 
    apiKey: String,
    userId: String,
    userToken: String,
    channelId: String,
    channelType: String,
    userName: String,
    userImage: String,
    canModerate: Boolean
  }

  connect() {
    this.initializeChat()
  }

  disconnect() {
    this.cleanup()
  }

  async initializeChat() {
    try {
      // Initialize GetStream.io client
      this.client = StreamChat.getInstance(this.apiKeyValue)
      
      // Get or fetch user token
      let userToken = this.userTokenValue
      if (userToken === "FETCH_VIA_API") {
        userToken = await this.fetchUserToken()
      }
      
      if (!userToken) {
        this.updateConnectionState('error', 'Access denied')
        return
      }
      
      // Connect user
      const user = {
        id: this.userIdValue,
        name: this.userNameValue,
        image: this.userImageValue
      }

      await this.client.connectUser(user, userToken)
      
      // Get or create channel
      this.channel = this.client.channel(this.channelTypeValue, this.channelId, {
        name: `Stream Chat - ${this.channelIdValue}`,
        members: [this.userIdValue]
      })

      await this.channel.watch()
      
      // Load existing messages
      this.loadMessages()
      
      // Listen for new messages
      this.channel.on('message.new', this.handleNewMessage.bind(this))
      this.channel.on('message.deleted', this.handleMessageDeleted.bind(this))
      this.channel.on('member.added', this.handleMemberAdded.bind(this))
      this.channel.on('member.removed', this.handleMemberRemoved.bind(this))
      
      // Update UI state
      this.updateConnectionState('connected')
      
    } catch (error) {
      console.error('Failed to initialize chat:', error)
      this.updateConnectionState('error', error.message)
    }
  }

  async loadMessages() {
    try {
      const result = await this.channel.query({
        messages: { limit: 50 }
      })
      
      // Clear existing messages
      this.messagesTarget.innerHTML = ''
      
      // Render messages
      result.messages.forEach(message => {
        this.renderMessage(message)
      })
      
      // Scroll to bottom
      this.scrollToBottom()
      
    } catch (error) {
      console.error('Failed to load messages:', error)
    }
  }

  async sendMessage(event) {
    event.preventDefault()
    
    const messageText = this.inputTarget.value.trim()
    if (!messageText) return
    
    try {
      // Disable send button
      this.sendButtonTarget.disabled = true
      this.inputTarget.disabled = true
      
      await this.channel.sendMessage({
        text: messageText,
        user_id: this.userIdValue
      })
      
      // Clear input
      this.inputTarget.value = ''
      
    } catch (error) {
      console.error('Failed to send message:', error)
      alert('Failed to send message. Please try again.')
    } finally {
      // Re-enable controls
      this.sendButtonTarget.disabled = false
      this.inputTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  handleKeyPress(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.sendMessage(event)
    }
  }

  handleNewMessage(event) {
    this.renderMessage(event.message)
    this.scrollToBottom()
  }

  handleMessageDeleted(event) {
    const messageElement = this.messagesTarget.querySelector(`[data-message-id="${event.message.id}"]`)
    if (messageElement) {
      messageElement.remove()
    }
  }

  handleMemberAdded(event) {
    if (this.hasUserListTarget) {
      this.updateUserList()
    }
  }

  handleMemberRemoved(event) {
    if (this.hasUserListTarget) {
      this.updateUserList()
    }
  }

  renderMessage(message) {
    const messageElement = document.createElement('div')
    messageElement.className = 'chat-message flex gap-3 p-3 hover:bg-gray-50'
    messageElement.setAttribute('data-message-id', message.id)
    
    const isOwnMessage = message.user.id === this.userIdValue
    const timestamp = new Date(message.created_at).toLocaleTimeString()
    
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
          ${this.canModerateValue && !isOwnMessage ? this.renderModerationActions(message) : ''}
        </div>
        <div class="text-sm text-gray-700 break-words">
          ${this.escapeHtml(message.text)}
        </div>
      </div>
    `
    
    this.messagesTarget.appendChild(messageElement)
  }

  renderModerationActions(message) {
    return `
      <div class="flex gap-1 ml-auto">
        <button onclick="this.closest('[data-controller=\"chat\"]').controller.deleteMessage('${message.id}')"
                class="text-xs text-red-500 hover:text-red-700 px-1">
          Delete
        </button>
        <button onclick="this.closest('[data-controller=\"chat\"]').controller.banUser('${message.user.id}')"
                class="text-xs text-red-500 hover:text-red-700 px-1">
          Ban
        </button>
      </div>
    `
  }

  async deleteMessage(messageId) {
    if (!this.canModerateValue) return
    
    try {
      await this.channel.deleteMessage(messageId)
    } catch (error) {
      console.error('Failed to delete message:', error)
      alert('Failed to delete message.')
    }
  }

  async banUser(userId) {
    if (!this.canModerateValue) return
    
    const reason = prompt('Enter ban reason (optional):')
    if (reason === null) return // User cancelled
    
    try {
      await this.channel.banUser(userId, {
        reason: reason || 'Violated chat rules',
        timeout: 60 * 60 * 24 // 24 hours
      })
      
      alert('User banned successfully.')
    } catch (error) {
      console.error('Failed to ban user:', error)
      alert('Failed to ban user.')
    }
  }

  async updateUserList() {
    if (!this.hasUserListTarget) return
    
    try {
      const members = await this.channel.queryMembers({})
      
      this.userListTarget.innerHTML = members.members.map(member => `
        <div class="flex items-center gap-2 p-2">
          <img src="${member.user.image || '/placeholder-avatar.png'}" 
               alt="${member.user.name}" 
               class="w-6 h-6 rounded-full">
          <span class="text-sm text-gray-700">${member.user.name}</span>
          ${member.user.id === this.userIdValue ? '<span class="text-xs text-blue-500">(You)</span>' : ''}
        </div>
      `).join('')
      
    } catch (error) {
      console.error('Failed to update user list:', error)
    }
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
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

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // Fetch user token from backend with access control
  async fetchUserToken() {
    try {
      const streamId = this.getStreamId()
      const response = await fetch(`/account/streams/${streamId}/chat_token`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        return data.success ? data.token : null
      } else if (response.status === 403) {
        const errorData = await response.json()
        this.handleAccessDenied(errorData)
        return null
      } else {
        throw new Error(`HTTP ${response.status}`)
      }
    } catch (error) {
      console.error('Failed to fetch chat token:', error)
      return null
    }
  }

  // Join chat room via backend
  async joinChatRoom() {
    try {
      const streamId = this.getStreamId()
      const response = await fetch(`/account/streams/${streamId}/join_chat`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        console.log('Joined chat room:', data.message)
        return true
      } else {
        const errorData = await response.json()
        console.error('Failed to join chat:', errorData.message)
        return false
      }
    } catch (error) {
      console.error('Error joining chat room:', error)
      return false
    }
  }

  // Leave chat room via backend
  async leaveChatRoom() {
    try {
      const streamId = this.getStreamId()
      const response = await fetch(`/account/streams/${streamId}/leave_chat`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        console.log('Left chat room:', data.message)
        return true
      } else {
        console.error('Failed to leave chat')
        return false
      }
    } catch (error) {
      console.error('Error leaving chat room:', error)
      return false
    }
  }

  // Handle access denied scenarios
  handleAccessDenied(errorData) {
    let message = errorData.message || 'Access denied'
    
    if (errorData.access_required) {
      message = 'Please sign in to access chat'
    } else if (errorData.pass_required) {
      message = 'Access Pass required for chat'
    }
    
    this.updateConnectionState('error', message)
    
    // Replace chat widget with access denied message
    const accessDeniedHTML = `
      <div class="chat-access-denied bg-red-50 border border-red-200 rounded-lg p-4">
        <div class="flex items-center gap-3">
          <svg class="w-6 h-6 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z">
            </path>
          </svg>
          <div>
            <h3 class="font-semibold text-red-900">Chat Access Restricted</h3>
            <p class="text-red-800 text-sm">${message}</p>
          </div>
        </div>
      </div>
    `
    
    this.element.innerHTML = accessDeniedHTML
  }

  // Helper methods
  getStreamId() {
    // Extract stream ID from URL or data attribute
    const url = window.location.pathname
    const match = url.match(/\/streams\/(\d+)/)
    return match ? match[1] : null
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  cleanup() {
    // Leave chat room when disconnecting
    if (this.channel) {
      this.leaveChatRoom()
      this.channel.stopWatching()
    }
    if (this.client) {
      this.client.disconnectUser()
    }
  }
}