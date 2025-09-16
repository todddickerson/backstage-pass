module ChatAccessControl
  extend ActiveSupport::Concern

  included do
    before_action :verify_chat_access, only: [:show, :join_chat, :leave_chat, :chat_token]
  end

  private

  def verify_chat_access
    # Use obfuscated_id for finding records per Bullet Train override
    @stream = Stream.find_by_obfuscated_id(params[:id] || params[:stream_id])
    
    unless @stream
      respond_to_chat_access_denied("Stream not found")
      return false
    end
    
    unless current_user
      respond_to_chat_access_denied("Authentication required")
      return false
    end

    unless @stream.can_view?(current_user)
      respond_to_chat_access_denied("Access Pass required")
      return false
    end

    # Check if user is banned from this specific chat
    if user_banned_from_chat?(@stream, current_user)
      respond_to_chat_access_denied("You have been banned from this chat")
      return false
    end

    # All checks passed
    true
  end

  def user_banned_from_chat?(stream, user)
    # Check GetStream.io for ban status
    chat_room = stream.chat_room
    return false unless chat_room&.channel_id

    begin
      chat_service = Streaming::ChatService.new
      
      # Query ban list for this user in this channel
      # GetStream.io API call to check if user is banned
      channel = chat_service.client.channel('livestream', chat_room.channel_id)
      ban_info = channel.query_banned_users(filter_conditions: { 
        target_user_id: user.id.to_s 
      })
      
      # Check if there's an active ban
      ban_info.dig('bans')&.any? { |ban| 
        ban['expires'].nil? || Time.parse(ban['expires']) > Time.current 
      }
      
    rescue => e
      Rails.logger.error "Failed to check ban status: #{e.message}"
      # Fail open - don't block access due to API errors
      false
    end
  end

  def respond_to_chat_access_denied(message)
    respond_to do |format|
      format.html do
        flash[:alert] = message
        redirect_to [@stream.experience.space]
      end
      
      format.json do
        render json: { 
          error: "Access Denied", 
          message: message,
          access_required: !current_user,
          pass_required: current_user && !@stream.can_view?(current_user)
        }, status: :forbidden
      end
      
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "chat-widget",
          partial: "shared/chat/access_denied",
          locals: { message: message, stream: @stream }
        )
      end
    end
  end

  # Generate chat access token with proper permissions
  def generate_chat_token_for_user(user, stream)
    chat_service = Streaming::ChatService.new
    
    # Determine user role in chat
    role = if stream.can_broadcast?(user)
      'admin'  # Creator/team member
    elsif stream.can_view?(user)
      'user'   # Valid access pass holder
    else
      nil      # No access
    end
    
    return nil unless role
    
    # Generate token with role-based permissions
    # GetStream.io tokens are simple JWTs with user_id
    # Additional data should be stored in user metadata
    chat_service.generate_user_token(user.id.to_s)
  end

  # Middleware to add user to chat room with proper role
  def add_user_to_chat_room(stream, user)
    chat_room = stream.chat_room
    return false unless chat_room&.channel_id

    begin
      # Determine role
      role = if stream.can_broadcast?(user)
        'moderator'
      else
        'member'
      end
      
      # Add user to GetStream.io channel
      chat_room.add_user(user, role: role)
      
      # Log chat access for analytics
      log_chat_access(stream, user, 'joined')
      
      true
    rescue => e
      Rails.logger.error "Failed to add user to chat room: #{e.message}"
      false
    end
  end

  def remove_user_from_chat_room(stream, user)
    chat_room = stream.chat_room
    return false unless chat_room&.channel_id

    begin
      chat_room.remove_user(user)
      log_chat_access(stream, user, 'left')
      true
    rescue => e
      Rails.logger.error "Failed to remove user from chat room: #{e.message}"
      false
    end
  end

  def log_chat_access(stream, user, action)
    Rails.logger.info "Chat Access: User #{user.id} #{action} stream #{stream.id} chat"
    
    # Optionally store in analytics/audit log
    # ChatAccessLog.create!(
    #   user: user,
    #   stream: stream,
    #   action: action,
    #   ip_address: request.remote_ip,
    #   user_agent: request.user_agent
    # )
  end

  # Check if user's access pass is still valid
  def validate_ongoing_access(stream, user)
    # Re-check access pass validity (in case it expired during the session)
    return false unless stream.can_view?(user)
    
    # Check if user is still active (not banned/suspended)
    return false unless user.active? if user.respond_to?(:active?)
    
    true
  end

  # Rate limiting for chat actions
  def check_chat_rate_limit(user, action = 'message')
    cache_key = "chat_rate_limit:#{user.id}:#{action}"
    
    # Different limits for different actions
    limits = {
      'message' => { count: 10, period: 1.minute },
      'join' => { count: 5, period: 1.minute },
      'moderation' => { count: 20, period: 1.minute }
    }
    
    limit = limits[action] || limits['message']
    
    # Use Rails cache for rate limiting
    current_count = Rails.cache.read(cache_key) || 0
    
    if current_count >= limit[:count]
      respond_to do |format|
        format.json do
          render json: { 
            error: "Rate Limit Exceeded", 
            message: "Please slow down your #{action} requests",
            retry_after: limit[:period].to_i
          }, status: :too_many_requests
        end
      end
      return false
    end
    
    # Increment counter
    Rails.cache.write(cache_key, current_count + 1, expires_in: limit[:period])
    true
  end
end