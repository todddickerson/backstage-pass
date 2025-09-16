class Account::Streaming::ChatRoomsController < Account::ApplicationController
  account_load_and_authorize_resource :chat_room, through: :stream, through_association: :streaming_chat_rooms

  # GET /account/streams/:stream_id/streaming/chat_rooms
  # GET /account/streams/:stream_id/streaming/chat_rooms.json
  def index
    delegate_json_to_api
  end

  # GET /account/streaming/chat_rooms/:id
  # GET /account/streaming/chat_rooms/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/streams/:stream_id/streaming/chat_rooms/new
  def new
  end

  # GET /account/streaming/chat_rooms/:id/edit
  def edit
  end

  # POST /account/streams/:stream_id/streaming/chat_rooms
  # POST /account/streams/:stream_id/streaming/chat_rooms.json
  def create
    respond_to do |format|
      if @chat_room.save
        format.html { redirect_to [:account, @chat_room], notice: I18n.t("streaming/chat_rooms.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @chat_room] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chat_room.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/streaming/chat_rooms/:id
  # PATCH/PUT /account/streaming/chat_rooms/:id.json
  def update
    respond_to do |format|
      if @chat_room.update(chat_room_params)
        format.html { redirect_to [:account, @chat_room], notice: I18n.t("streaming/chat_rooms.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @chat_room] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chat_room.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/streaming/chat_rooms/:id
  # DELETE /account/streaming/chat_rooms/:id.json
  def destroy
    @chat_room.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @stream, :streaming_chat_rooms], notice: I18n.t("streaming/chat_rooms.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
