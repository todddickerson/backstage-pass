class Account::StreamsController < Account::ApplicationController
  include ChatAccessControl
  
  account_load_and_authorize_resource :stream, through: :experience, through_association: :streams

  # GET /account/experiences/:experience_id/streams
  # GET /account/experiences/:experience_id/streams.json
  def index
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
        format.json { render :show, status: :created, location: [:account, @stream] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @stream.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/streams/:id
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
      render json: { success: true, message: "Successfully left chat" }
    else
      render json: { success: false, message: "Failed to leave chat" }, status: :unprocessable_entity
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
        user_name: current_user.name || current_user.email.split('@').first
      }
    else
      render json: { 
        success: false, 
        message: "Unable to generate chat token" 
      }, status: :forbidden
    end
  end

  private

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    assign_date_and_time(strong_params, :scheduled_at)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
