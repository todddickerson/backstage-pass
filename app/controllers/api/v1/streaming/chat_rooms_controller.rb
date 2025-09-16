# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::Streaming::ChatRoomsController < Api::V1::ApplicationController
    account_load_and_authorize_resource :chat_room, through: :stream, through_association: :streaming_chat_rooms

    # GET /api/v1/streams/:stream_id/streaming/chat_rooms
    def index
    end

    # GET /api/v1/streaming/chat_rooms/:id
    def show
    end

    # POST /api/v1/streams/:stream_id/streaming/chat_rooms
    def create
      if @chat_room.save
        render :show, status: :created, location: [:api, :v1, @chat_room]
      else
        render json: @chat_room.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/streaming/chat_rooms/:id
    def update
      if @chat_room.update(chat_room_params)
        render :show
      else
        render json: @chat_room.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/streaming/chat_rooms/:id
    def destroy
      @chat_room.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def chat_room_params
        strong_params = params.require(:streaming_chat_room).permit(
          *permitted_fields,
          :stream_id,
          :channel_id,
          # 🚅 super scaffolding will insert new fields above this line.
          *permitted_arrays,
          # 🚅 super scaffolding will insert new arrays above this line.
        )

        process_params(strong_params)

        strong_params
      end
    end

    include StrongParameters
  end
else
  class Api::V1::Streaming::ChatRoomsController
  end
end
