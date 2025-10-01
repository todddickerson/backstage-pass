class Streaming::ChatRoom < ApplicationRecord
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :stream
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  has_one :team, through: :stream
  has_one :experience, through: :stream
  has_one :space, through: :experience
  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  validates :channel_id, uniqueness: true, allow_blank: true
  # 🚅 add validations above.

  after_destroy :cleanup_getstream_channel
  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # Alias for channel_id to make intent clearer in views/controllers
  def getstream_channel_id
    channel_id
  end

  # Initialize GetStream.io chat service
  def chat_service
    @chat_service ||= Streaming::ChatService.new
  end

  # Create the actual GetStream.io channel
  def create_chat_channel!
    return false if channel_id.present?

    # Generate unique channel ID
    generated_id = "stream_#{stream.id}_#{SecureRandom.hex(4)}"

    # Create channel in GetStream.io
    channel = chat_service.create_chat_room(
      chatroom_id: generated_id,
      name: stream.title,
      created_by_user_id: stream.experience.space.team.users.first.id.to_s,
      metadata: {
        stream_id: stream.id,
        experience_id: stream.experience.id,
        space_id: stream.experience.space.id,
        team_id: stream.experience.space.team.id
      }
    )

    # Update our record with the channel ID
    update!(channel_id: generated_id)
    channel
  end

  # Add user to chat room
  def add_user(user, role: "member")
    chat_service.add_user_to_room(
      chatroom_id: channel_id,
      user_id: user.id.to_s,
      role: role
    )
  end

  # Remove user from chat room
  def remove_user(user)
    chat_service.remove_user_from_room(
      chatroom_id: channel_id,
      user_id: user.id.to_s
    )
  end

  # Ban user from chat room
  def ban_user(user, banned_by:, reason: nil, timeout_minutes: nil)
    chat_service.ban_user(
      chatroom_id: channel_id,
      user_id: user.id.to_s,
      banned_by_id: banned_by.id.to_s,
      reason: reason,
      timeout_minutes: timeout_minutes
    )
  end

  # Check if user can access this chat room
  def can_access?(user)
    stream.can_view?(user)
  end

  # Check if user can moderate this chat room
  def can_moderate?(user)
    stream.can_broadcast?(user)
  end

  private

  def cleanup_getstream_channel
    return unless channel_id.present?

    chat_service.delete_chat_room(chatroom_id: channel_id)
  rescue => e
    Rails.logger.error "Failed to cleanup GetStream channel #{channel_id}: #{e.message}"
  end

  # 🚅 add methods above.
end
