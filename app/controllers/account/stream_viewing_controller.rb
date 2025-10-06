class Account::StreamViewingController < Account::ApplicationController
  layout "streaming"  # Use dedicated full-screen streaming layout
  include ChatAccessControl

  before_action :set_stream
  before_action :verify_stream_access
  before_action :ensure_chat_room, only: [:show, :chat_token]

  # GET /account/streams/:id/view
  def show
    # Set up variables for the streaming interface
    @experience = @stream.experience
    @space = @experience.space
    @chat_room = @stream.chat_room

    # Get user's access grant for this content
    @access_grant = current_user.access_grants.find do |grant|
      grant.active? && (grant.grants_access_to?(@stream) || grant.grants_access_to?(@experience) || grant.grants_access_to?(@space))
    end

    # Check if stream is currently accessible
    @stream_accessible = stream_accessible?

    respond_to do |format|
      format.html
      format.json { render json: stream_viewing_json }
    end
  end

  # GET /account/streams/:id/video_token
  def video_token
    return render_access_denied unless @stream.can_view?(current_user)

    livekit_service = Streaming::LivekitService.new
    connection_info = livekit_service.generate_mobile_connection_info(@stream, current_user)

    render json: {
      success: true,
      **connection_info
    }
  rescue => e
    Rails.logger.error "Failed to generate video token: #{e.message}"
    render json: {
      success: false,
      message: "Unable to generate video token"
    }, status: :internal_server_error
  end

  # GET /account/streams/:id/chat_token
  def chat_token
    return render_access_denied unless @stream.can_view?(current_user)

    token = generate_chat_token_for_user(current_user, @stream)

    if token
      render json: {
        success: true,
        token: token,
        api_key: ENV["GETSTREAM_API_KEY"],
        user_id: current_user.id.to_s,
        user_name: current_user.name || current_user.email.split("@").first,
        chat_room_id: @chat_room.channel_id
      }
    else
      render json: {
        success: false,
        message: "Unable to generate chat token"
      }, status: :forbidden
    end
  end

  # GET /account/streams/:id/stream_info
  def stream_info
    return render_access_denied unless @stream.can_view?(current_user)

    # Set experience and space (needed for response)
    @experience = @stream.experience
    @space = @experience.space

    livekit_service = Streaming::LivekitService.new
    room_info = livekit_service.get_room_info(@stream)
    participants = livekit_service.get_room_participants(@stream)

    render json: {
      success: true,
      stream: {
        id: @stream.id,
        title: @stream.title,
        status: @stream.status,
        scheduled_at: @stream.scheduled_at,
        room_name: @stream.room_name
      },
      experience: {
        id: @experience.id,
        name: @experience.name,
        slug: @experience.slug
      },
      space: {
        id: @space.id,
        name: @space.name,
        slug: @space.slug
      },
      room_info: room_info,
      participants: participants,
      participant_count: participants&.length || 0,
      can_view: @stream.can_view?(current_user),
      can_broadcast: @stream.can_broadcast?(current_user)
    }
  rescue => e
    Rails.logger.error "Failed to get stream info: #{e.message}"
    render json: {
      success: false,
      message: "Unable to get stream information"
    }, status: :internal_server_error
  end

  # POST /account/streams/:id/join_chat
  def join_chat
    return render_access_denied unless @stream.can_view?(current_user)

    if add_user_to_chat_room(@stream, current_user)
      render json: {
        success: true,
        message: "Successfully joined chat",
        user_token: generate_chat_token_for_user(current_user, @stream)
      }
    else
      render json: {
        success: false,
        message: "Failed to join chat"
      }, status: :unprocessable_entity
    end
  end

  # DELETE /account/streams/:id/leave_chat
  def leave_chat
    return render_access_denied unless @stream.can_view?(current_user)

    if remove_user_from_chat_room(@stream, current_user)
      render json: {success: true, message: "Successfully left chat"}
    else
      render json: {success: false, message: "Failed to leave chat"}, status: :unprocessable_entity
    end
  end

  private

  def set_stream
    @stream = Stream.find(params[:id])
  end

  def verify_stream_access
    unless @stream.can_view?(current_user)
      if request.format.json?
        render_access_denied
      else
        @experience = @stream.experience
        @space = @experience.space

        redirect_to public_space_path(@space.slug),
          alert: "Access Pass required to view this stream. Please purchase access to continue."
      end
    end
  end

  def ensure_chat_room
    @chat_room = @stream.chat_room
  end

  def stream_accessible?
    # Team members (creators) always have access to their streams
    return true if @stream.experience.space.team.users.include?(current_user)

    # For viewers/buyers:
    return true if @stream.live?
    return true if @stream.ended? && recording_available?
    return false if @stream.scheduled? && @stream.scheduled_at.present? && @stream.scheduled_at > Time.current

    # For scheduled streams starting soon (within 5 minutes)
    @stream.scheduled? && @stream.scheduled_at.present? && @stream.scheduled_at <= 5.minutes.from_now
  end

  def recording_available?
    # For now, assume recordings are available for ended streams
    # This can be enhanced later with actual recording status
    @stream.ended?
  end

  def render_access_denied
    render json: {
      success: false,
      message: "Access Pass required to view this stream",
      redirect_url: public_space_path(@stream.experience.space.slug)
    }, status: :forbidden
  end

  def stream_viewing_json
    {
      stream: {
        id: @stream.id,
        title: @stream.title,
        description: @stream.description.to_s,
        status: @stream.status,
        scheduled_at: @stream.scheduled_at,
        room_name: @stream.room_name,
        accessible: @stream_accessible
      },
      experience: {
        id: @experience.id,
        name: @experience.name,
        slug: @experience.slug
      },
      space: {
        id: @space.id,
        name: @space.name,
        slug: @space.slug
      },
      access_grant: @access_grant ? {
        id: @access_grant.id,
        expires_at: @access_grant.expires_at,
        status: @access_grant.status
      } : nil,
      chat_room: @chat_room ? {
        id: @chat_room.id,
        channel_id: @chat_room.channel_id
      } : nil,
      permissions: {
        can_view: @stream.can_view?(current_user),
        can_broadcast: @stream.can_broadcast?(current_user),
        can_chat: @stream.can_view?(current_user)
      }
    }
  end
end
