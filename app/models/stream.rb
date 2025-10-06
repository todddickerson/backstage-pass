class Stream < ApplicationRecord
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :experience, counter_cache: true
  # 🚅 add belongs_to associations above.

  has_many :streaming_chat_rooms, class_name: "Streaming::ChatRoom", dependent: :destroy
  # 🚅 add has_many associations above.

  has_one :team, through: :experience
  has_rich_text :description
  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  validates :title, presence: true
  validates :status, presence: true
  # 🚅 add validations above.

  after_update :handle_status_change, if: :saved_change_to_status?
  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # Status enum for stream lifecycle
  enum :status, {
    scheduled: "scheduled",
    rehearsal: "rehearsal",  # Testing mode - only broadcaster can see
    live: "live",            # Public - viewers can join
    ended: "ended"
  }

  # Generate LiveKit room name based on stream ID
  def room_name
    "stream_#{id}"
  end

  # Check if user can view this stream
  def can_view?(user)
    # REHEARSAL MODE: Only broadcaster can view
    if rehearsal?
      return experience.space.team.users.include?(user)
    end

    # Team members (creators) always have access
    return true if experience.space.team.users.include?(user)

    # FREE CONTENT: Allow access if experience is free
    return true if experience.price_cents == 0

    # PAID CONTENT: Check if user has valid access pass
    return false unless user

    user.access_grants.where(
      purchasable: [experience, experience.space]
    ).any?(&:active?)
  end

  # Check if user can broadcast (host) this stream
  def can_broadcast?(user)
    return false unless user

    # User must be a team member, but not just a "buyer" (access pass holder)
    membership = experience.space.team.memberships.find_by(user: user)
    return false unless membership

    # Buyers (access pass holders) cannot broadcast
    !membership.role_ids.include?("buyer") || membership.role_ids.length > 1
  end

  # Generate a unique stream URL for public viewing
  def public_url
    "/#{experience.space.slug}/#{experience.slug}/streams/#{id}"
  end

  # Get or create chat room for this stream
  def chat_room
    streaming_chat_rooms.first || create_chat_room!
  end

  # Create a new chat room for this stream
  def create_chat_room!
    chat_room = streaming_chat_rooms.create!
    chat_room.create_chat_channel!
    chat_room
  end

  # Create LiveKit room when stream goes live
  def create_livekit_room
    return unless live?
    return if livekit_room_name.present? # Already created

    livekit_service = Streaming::LivekitService.new
    room = livekit_service.create_room(self)

    if room
      Rails.logger.info "LiveKit room created: #{room.name} (SID: #{room.sid})"
      update_column(:started_at, Time.current) unless started_at.present?
    end
  rescue => e
    Rails.logger.error "Failed to create LiveKit room: #{e.message}"
    # Don't fail the stream status change, just log the error
  end

  # Cleanup LiveKit room when stream ends
  def cleanup_livekit_room
    return unless ended?
    return unless livekit_room_name.present?

    livekit_service = Streaming::LivekitService.new
    livekit_service.delete_room(self)

    Rails.logger.info "LiveKit room deleted: #{livekit_room_name}"
    update_column(:ended_at, Time.current) unless ended_at.present?
  rescue => e
    Rails.logger.error "Failed to delete LiveKit room: #{e.message}"
    # Continue anyway - room will eventually timeout
  end

  # Handle stream status changes
  def handle_status_change
    case status
    when "live"
      create_livekit_room
      # Ensure chat room exists
      chat_room
    when "ended"
      cleanup_livekit_room
    end
  end

  # 🚅 add methods above.
end
