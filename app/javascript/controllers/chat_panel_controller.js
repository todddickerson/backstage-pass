import { Controller } from "@hotwired/stimulus"

/**
 * Chat Panel Controller
 * Handles chat/viewers tab switching, emoji reactions, and moderation controls
 */
export default class extends Controller {
  static targets = [
    "chatTab", "viewersTab",
    "chatPanel", "viewersPanel",
    "slowModeBtn", "followersBtn"
  ]

  connect() {
    console.log('💬 Chat panel controller connected')
    this.slowModeEnabled = false
    this.followersOnlyEnabled = false
  }

  // Tab Switching
  showChat() {
    if (!this.hasChatPanelTarget || !this.hasViewersPanelTarget) return

    // Switch panels
    this.chatPanelTarget.classList.remove('hidden')
    this.viewersPanelTarget.classList.add('hidden')

    // Update tab styles
    if (this.hasChatTabTarget && this.hasViewersTabTarget) {
      this.chatTabTarget.classList.add('bg-gray-800', 'text-white')
      this.chatTabTarget.classList.remove('text-gray-400')

      this.viewersTabTarget.classList.remove('bg-gray-800', 'text-white')
      this.viewersTabTarget.classList.add('text-gray-400')
    }
  }

  showViewers() {
    if (!this.hasChatPanelTarget || !this.hasViewersPanelTarget) return

    // Switch panels
    this.chatPanelTarget.classList.add('hidden')
    this.viewersPanelTarget.classList.remove('hidden')

    // Update tab styles
    if (this.hasChatTabTarget && this.hasViewersTabTarget) {
      this.viewersTabTarget.classList.add('bg-gray-800', 'text-white')
      this.viewersTabTarget.classList.remove('text-gray-400')

      this.chatTabTarget.classList.remove('bg-gray-800', 'text-white')
      this.chatTabTarget.classList.add('text-gray-400')
    }

    // Refresh viewers list
    this.refreshViewersList()
  }

  // Quick Emoji Reactions
  sendEmoji(event) {
    const emoji = event.currentTarget.dataset.emoji
    if (!emoji) return

    // Get stream-viewer controller and send emoji as message
    const streamViewerElement = this.element.closest('[data-controller~="stream-viewer"]')
    if (streamViewerElement) {
      const streamViewer = this.application.getControllerForElementAndIdentifier(
        streamViewerElement,
        'stream-viewer'
      )

      if (streamViewer && streamViewer.sendMessage) {
        streamViewer.sendMessage(emoji)
      }
    }
  }

  toggleEmojiPicker(event) {
    // TODO: Implement full emoji picker modal
    // For now, users can use quick reactions or type emojis
    console.log('Emoji picker (coming soon)')
  }

  // Moderation Controls
  toggleSlowMode() {
    this.slowModeEnabled = !this.slowModeEnabled

    if (this.hasSlowModeBtnTarget) {
      if (this.slowModeEnabled) {
        this.slowModeBtnTarget.classList.add('bg-yellow-600')
        this.slowModeBtnTarget.classList.remove('bg-gray-700')
      } else {
        this.slowModeBtnTarget.classList.remove('bg-yellow-600')
        this.slowModeBtnTarget.classList.add('bg-gray-700')
      }
    }

    console.log(`🐌 Slow mode: ${this.slowModeEnabled ? 'enabled' : 'disabled'}`)

    // TODO: Implement slow mode via GetStream
    // this.chatChannel.update({ cooldown: this.slowModeEnabled ? 10 : 0 })
  }

  toggleFollowersOnly() {
    this.followersOnlyEnabled = !this.followersOnlyEnabled

    if (this.hasFollowersBtnTarget) {
      if (this.followersOnlyEnabled) {
        this.followersBtnTarget.classList.add('bg-purple-600')
        this.followersBtnTarget.classList.remove('bg-gray-700')
      } else {
        this.followersBtnTarget.classList.remove('bg-purple-600')
        this.followersBtnTarget.classList.add('bg-gray-700')
      }
    }

    console.log(`👥 Followers only: ${this.followersOnlyEnabled ? 'enabled' : 'disabled'}`)

    // TODO: Implement followers-only mode
  }

  clearChat() {
    if (!confirm('Clear all chat messages? This cannot be undone.')) return

    const chatMessages = document.querySelector('[data-stream-viewer-target="chatMessages"]')
    if (chatMessages) {
      chatMessages.innerHTML = '<p class="text-gray-500 text-sm text-center">Chat cleared by broadcaster</p>'
    }

    console.log('🗑️ Chat cleared')

    // TODO: Clear chat via GetStream API
    // this.chatChannel.truncate()
  }

  refreshViewersList() {
    // Get stream-viewer controller to access room participants
    const streamViewerElement = this.element.closest('[data-controller~="stream-viewer"]')
    if (!streamViewerElement) return

    const streamViewer = this.application.getControllerForElementAndIdentifier(
      streamViewerElement,
      'stream-viewer'
    )

    if (!streamViewer || !streamViewer.getRoom()) return

    const room = streamViewer.getRoom()
    const viewersList = document.querySelector('[data-stream-viewer-target="viewersList"]')
    if (!viewersList) return

    // Clear and rebuild list
    viewersList.innerHTML = ''

    // Add broadcaster (local participant)
    if (room.localParticipant) {
      const broadcasterDiv = this.createViewerElement(
        room.localParticipant.identity,
        true,
        room.localParticipant.metadata
      )
      viewersList.appendChild(broadcasterDiv)
    }

    // Add viewers (remote participants)
    room.participants.forEach((participant) => {
      const viewerDiv = this.createViewerElement(
        participant.identity,
        false,
        participant.metadata
      )
      viewersList.appendChild(viewerDiv)
    })

    // Show count
    const totalViewers = room.participants.size + 1 // Include broadcaster
    console.log(`👥 ${totalViewers} total participants`)
  }

  createViewerElement(identity, isBroadcaster, metadata) {
    const div = document.createElement('div')
    div.className = 'flex items-center justify-between p-2 bg-gray-800 rounded-lg hover:bg-gray-750 transition-colors'

    const name = metadata?.name || identity || 'Anonymous'

    div.innerHTML = `
      <div class="flex items-center space-x-2 flex-1 min-w-0">
        <div class="w-8 h-8 rounded-full ${isBroadcaster ? 'bg-purple-600' : 'bg-blue-600'} flex items-center justify-center flex-shrink-0">
          <span class="text-white text-xs font-bold">${name.charAt(0).toUpperCase()}</span>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-white text-sm font-medium truncate">${this.escapeHtml(name)}</p>
          ${isBroadcaster ? '<p class="text-purple-400 text-xs">Broadcaster</p>' : ''}
        </div>
      </div>
      ${isBroadcaster ? '' : `
        <button
          class="text-gray-400 hover:text-red-400 p-1"
          onclick="console.log('Kick user: ${identity}')"
          title="Kick user"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      `}
    `

    return div
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
