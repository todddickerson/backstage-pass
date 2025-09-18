class Public::ExperiencesController < Public::ApplicationController
  include ChatAccessControl

  before_action :set_space
  before_action :set_experience
  before_action :check_experience_access

  # GET /:space_slug/:experience_slug
  def show
    @streams = @experience.streams.includes(:streaming_chat_rooms)

    # For live streaming experiences, set up the active stream
    if @experience.live_streaming? && @streams.live.any?
      @active_stream = @streams.live.first
      @chat_room = @active_stream.chat_room if @active_stream
    end

    respond_to do |format|
      format.html
      format.json { render json: experience_json }
    end
  end

  # GET /:space_slug/:experience_slug/streams/:stream_id
  def stream
    @stream = @experience.streams.find(params[:stream_id])
    @chat_room = @stream.chat_room

    unless @stream.can_view?(current_user)
      if user_signed_in?
        redirect_to public_space_path(@space.slug),
          alert: "Access Pass required to view this stream"
      else
        redirect_to new_user_session_path,
          alert: "Please sign in to view this stream"
      end
      return
    end

    respond_to do |format|
      format.html { render :stream }
      format.json { render json: stream_json }
    end
  end

  # GET /:space_slug/:experience_slug/video_token
  def video_token
    return render_authentication_required unless user_signed_in?

    @stream = @experience.streams.find(params[:stream_id]) if params[:stream_id]
    @stream ||= @experience.streams.live.first

    return render_stream_not_found unless @stream
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

  # GET /:space_slug/:experience_slug/chat_token
  def chat_token
    return render_authentication_required unless user_signed_in?

    @stream = @experience.streams.find(params[:stream_id]) if params[:stream_id]
    @stream ||= @experience.streams.live.first

    return render_stream_not_found unless @stream
    return render_access_denied unless @stream.can_view?(current_user)

    token = generate_chat_token_for_user(current_user, @stream)

    if token
      render json: {
        success: true,
        token: token,
        user_id: current_user.id.to_s,
        user_name: current_user.name || current_user.email.split("@").first,
        chat_room_id: @stream.chat_room.getstream_channel_id
      }
    else
      render json: {
        success: false,
        message: "Unable to generate chat token"
      }, status: :forbidden
    end
  end

  # GET /:space_slug/:experience_slug/stream_info
  def stream_info
    @stream = @experience.streams.find(params[:stream_id]) if params[:stream_id]
    @stream ||= @experience.streams.live.first

    return render_stream_not_found unless @stream
    return render_access_denied unless @stream.can_view?(current_user)

    livekit_service = Streaming::LivekitService.new
    room_info = livekit_service.get_room_info(@stream)
    participants = livekit_service.get_room_participants(@stream)

    render json: {
      success: true,
      stream: {
        id: @stream.id,
        title: @stream.title,
        status: @stream.status,
        scheduled_at: @stream.scheduled_at
      },
      room_info: room_info,
      participants: participants,
      participant_count: participants&.length || 0
    }
  rescue => e
    Rails.logger.error "Failed to get stream info: #{e.message}"
    render json: {
      success: false,
      message: "Unable to get stream information"
    }, status: :internal_server_error
  end

  private

  def set_space
    @space = Space.published.friendly.find(params[:space_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Space not found"
  end

  def set_experience
    @experience = @space.experiences.find_by!(slug: params[:experience_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to public_space_path(@space.slug), alert: "Experience not found"
  end

  def check_experience_access
    # For now, just check if user can view the space
    # More granular access control can be added later
    return if @experience.accessible_by?(current_user)

    if user_signed_in?
      redirect_to public_space_path(@space.slug),
        alert: "Access Pass required to view this experience"
    else
      redirect_to new_user_session_path,
        alert: "Please sign in to view this experience"
    end
  end

  def render_authentication_required
    render json: {
      success: false,
      message: "Authentication required"
    }, status: :unauthorized
  end

  def render_access_denied
    render json: {
      success: false,
      message: "Access Pass required to view this content"
    }, status: :forbidden
  end

  def render_stream_not_found
    render json: {
      success: false,
      message: "Stream not found or not currently live"
    }, status: :not_found
  end

  def experience_json
    {
      id: @experience.id,
      name: @experience.name,
      description: @experience.description.to_s,
      experience_type: @experience.experience_type,
      price_display: @experience.price_display,
      streams: @streams.map do |stream|
        {
          id: stream.id,
          title: stream.title,
          status: stream.status,
          scheduled_at: stream.scheduled_at,
          viewer_count: stream.viewer_count || 0
        }
      end,
      active_stream: @active_stream ? {
        id: @active_stream.id,
        title: @active_stream.title,
        room_name: @active_stream.room_name
      } : nil
    }
  end

  def stream_json
    {
      id: @stream.id,
      title: @stream.title,
      description: @stream.description.to_s,
      status: @stream.status,
      scheduled_at: @stream.scheduled_at,
      room_name: @stream.room_name,
      viewer_count: @stream.viewer_count || 0,
      max_viewers: @stream.max_viewers || 0,
      chat_room: {
        id: @chat_room.id,
        getstream_channel_id: @chat_room.getstream_channel_id
      }
    }
  end
end
