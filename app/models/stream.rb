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

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # Status enum for stream lifecycle
  enum :status, {
    scheduled: "scheduled",
    live: "live",
    ended: "ended"
  }

  # Generate LiveKit room name based on stream ID
  def room_name
    "stream_#{id}"
  end

  # Check if user can view this stream
  def can_view?(user)
    return true if experience.space.team.users.include?(user)

    # Check if user has valid access pass for this experience or space
    user&.access_grants&.active&.where(
      purchasable: [experience, experience.space]
    )&.exists?
  end

  # Check if user can broadcast (host) this stream
  def can_broadcast?(user)
    return false unless user
    experience.space.team.users.include?(user)
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

  # 🚅 add methods above.
end
