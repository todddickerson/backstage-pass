class Account::StreamsController < Account::ApplicationController
  include ChatAccessControl

  before_action :set_experience
  before_action :set_stream, only: [:show, :edit, :update, :destroy, :join_chat, :leave_chat, :chat_token, :video_token, :start_stream, :stop_stream, :room_info]
  before_action :build_stream, only: [:new, :create]

  # GET /account/experiences/:experience_id/streams
  # GET /account/experiences/:experience_id/streams.json
  def index
    @streams = @experience.streams
    delegate_json_to_api
  end

  # GET /account/streams/:id
  # GET /account/streams/:id.json
  def show
    # Ensure chat room exists for this stream
    @stream.chat_room
    delegate_json_to_api
  end

  # GET /account/experiences/:experience_id/streams/new
  def new
  end

  # GET /account/streams/:id/edit
  def edit
  end

  # POST /account/experiences/:experience_id/streams
  # POST /account/experiences/:experience_id/streams.json
  def create
    respond_to do |format|
      if @stream.save
        format.html { redirect_to [:account, @stream], notice: I18n.t("streams.notifications.created") }
        format.turbo_stream { redirect_to [:account, @stream], notice: I18n.t("streams.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @stream] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.json { render json: @stream.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH//PUT /account/streams/:id
  # PATCH/PUT /account/streams/:id.json
  def update
    respond_to do |format|
      if @stream.update(stream_params)
        format.html { redirect_to [:account, @stream], notice: I18n.t("streams.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @stream] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stream.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/streams/:id
  # DELETE /account/streams/:id.json
  def destroy
    @stream.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @experience, :streams], notice: I18n.t("streams.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  # POST /account/streams/:id/join_chat
  def join_chat
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
    if remove_user_from_chat_room(@stream, current_user)
      render json: {success: true, message: "Successfully left chat"}
    else
      render json: {success: false, message: "Failed to leave chat"}, status: :unprocessable_entity
    end
  end

  # GET /account/streams/:id/chat_token
  def chat_token
    token = generate_chat_token_for_user(current_user, @stream)

    if token
      render json: {
        success: true,
        token: token,
        user_id: current_user.id.to_s,
        user_name: current_user.name || current_user.email.split("@").first
      }
    else
      render json: {
        success: false,
        message: "Unable to generate chat token"
      }, status: :forbidden
    end
  end

  # GET /account/streams/:id/video_token
  def video_token
    unless @stream.can_view?(current_user)
      render json: {
        success: false,
        message: "Access Pass required to view stream"
      }, status: :forbidden
      return
    end

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

  # POST /account/streams/:id/start_stream
  def start_stream
    unless @stream.can_broadcast?(current_user)
      render json: {
        success: false,
        message: "Not authorized to broadcast this stream"
      }, status: :forbidden
      return
    end

    if @stream.live?
      render json: {
        success: false,
        message: "Stream is already live"
      }, status: :unprocessable_entity
      return
    end

    livekit_service = Streaming::LivekitService.new

    begin
      # Create LiveKit room
      room = livekit_service.create_room(@stream)

      # Update stream status
      @stream.update!(status: :live)

      # Generate broadcaster token
      connection_info = livekit_service.generate_mobile_connection_info(@stream, current_user)

      render json: {
        success: true,
        message: "Stream started successfully",
        room_name: room.name,
        **connection_info
      }
    rescue => e
      Rails.logger.error "Failed to start stream: #{e.message}"
      render json: {
        success: false,
        message: "Failed to start stream: #{e.message}"
      }, status: :internal_server_error
    end
  end

  # POST /account/streams/:id/stop_stream
  def stop_stream
    unless @stream.can_broadcast?(current_user)
      render json: {
        success: false,
        message: "Not authorized to control this stream"
      }, status: :forbidden
      return
    end

    unless @stream.live?
      render json: {
        success: false,
        message: "Stream is not currently live"
      }, status: :unprocessable_entity
      return
    end

    livekit_service = Streaming::LivekitService.new

    begin
      # Delete LiveKit room
      livekit_service.delete_room(@stream)

      # Update stream status
      @stream.update!(status: :ended)

      render json: {
        success: true,
        message: "Stream stopped successfully"
      }
    rescue => e
      Rails.logger.error "Failed to stop stream: #{e.message}"
      render json: {
        success: false,
        message: "Failed to stop stream: #{e.message}"
      }, status: :internal_server_error
    end
  end

  # GET /account/streams/:id/room_info
  def room_info
    unless @stream.can_view?(current_user)
      render json: {
        success: false,
        message: "Access Pass required to view stream"
      }, status: :forbidden
      return
    end

    livekit_service = Streaming::LivekitService.new
    room_info = livekit_service.get_room_info(@stream)
    participants = livekit_service.get_room_participants(@stream)

    render json: {
      success: true,
      room_info: room_info,
      participants: participants,
      participant_count: participants&.length || 0
    }
  rescue => e
    Rails.logger.error "Failed to get room info: #{e.message}"
    render json: {
      success: false,
      message: "Unable to get room information"
    }, status: :internal_server_error
  end

  private

  def set_experience
    experience_id = params[:experience_id] || @stream&.experience_id
    @experience = current_user.experiences.find_by(id: experience_id) || current_user.experiences.first
  end

  def set_stream
    @stream = @experience.streams.find(params[:id])
  end

  def build_stream
    @stream = @experience.streams.build(stream_params) if params[:stream]
    @stream ||= @experience.streams.build
  end

  def stream_params
    return {} unless params[:stream]
    params.require(:stream).permit(:title, :description, :scheduled_at, :status)
  end

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    assign_date_and_time(strong_params, :scheduled_at)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
