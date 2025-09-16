require 'stream-chat'

module Streaming
  class ChatService
    attr_reader :client

    def initialize
      @client = StreamChat::Client.new(
        ENV['GETSTREAM_API_KEY'],
        ENV['GETSTREAM_API_SECRET']
      )
    end

    # Create a chat room for a stream or experience
    def create_chat_room(chatroom_id:, name:, created_by_user_id:, metadata: {})
      channel_data = {
        'name' => name,
        'created_by_id' => created_by_user_id,
        'custom' => metadata
      }

      # Note: Channel types like 'livestream' are pre-defined in GetStream.io
      # We just create channel instances, not channel types
      client.channel('livestream', channel_id: chatroom_id, data: channel_data)
    end

    # Generate user token for authentication
    def generate_user_token(user_id)
      client.create_token(user_id)
    end

    # Create or update user in GetStream
    def upsert_user(user)
      user_data = {
        id: user.id.to_s,
        name: user.name || user.email.split('@').first,
        image: user.profile_photo_url || nil,
        custom: {
          team_ids: user.team_ids,
          email: user.email
        }
      }

      client.upsert_user(user_data)
    end

    # Add user to chat room
    def add_user_to_room(chatroom_id:, user_id:, role: 'member')
      channel = client.channel('livestream', chatroom_id)
      channel.add_members([user_id], message: nil)
    end

    # Remove user from chat room
    def remove_user_from_room(chatroom_id:, user_id:)
      channel = client.channel('livestream', chatroom_id)
      channel.remove_members([user_id])
    end

    # Send moderation action (delete message, ban user, etc.)
    def moderate_message(chatroom_id:, message_id:, action: 'delete')
      channel = client.channel('livestream', chatroom_id)
      
      case action
      when 'delete'
        channel.delete_message(message_id)
      when 'flag'
        client.flag_message(message_id)
      end
    end

    # Ban user from chat room
    def ban_user(chatroom_id:, user_id:, banned_by_id:, reason: nil, timeout_minutes: nil)
      channel = client.channel('livestream', chatroom_id)
      
      ban_data = {
        type: 'channel',
        target_user_id: user_id,
        banned_by_id: banned_by_id,
        channel_type: 'livestream',
        channel_id: chatroom_id
      }
      
      ban_data[:reason] = reason if reason
      ban_data[:timeout] = timeout_minutes * 60 if timeout_minutes
      
      client.ban_user(**ban_data)
    end

    # Unban user from chat room
    def unban_user(chatroom_id:, user_id:)
      client.unban_user(
        target_user_id: user_id,
        channel_type: 'livestream',
        channel_id: chatroom_id
      )
    end

    # Get chat room members
    def get_room_members(chatroom_id:)
      channel = client.channel('livestream', chatroom_id)
      channel.query_members({})
    end

    # Get chat room messages (with pagination)
    def get_room_messages(chatroom_id:, limit: 20, id_lt: nil)
      channel = client.channel('livestream', chatroom_id)
      
      query_options = { limit: limit }
      query_options[:id_lt] = id_lt if id_lt
      
      channel.query(query_options)
    end

    # Delete/deactivate chat room
    def delete_chat_room(chatroom_id:)
      channel = client.channel('livestream', chatroom_id)
      channel.delete
    end

    private

    def validate_environment_variables!
      required_vars = %w[GETSTREAM_API_KEY GETSTREAM_API_SECRET]
      missing_vars = required_vars.select { |var| ENV[var].blank? }
      
      if missing_vars.any?
        raise "Missing GetStream.io environment variables: #{missing_vars.join(', ')}"
      end
    end
  end
end