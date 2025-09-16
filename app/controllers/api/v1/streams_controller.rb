# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::StreamsController < Api::V1::ApplicationController
    account_load_and_authorize_resource :stream, through: :experience, through_association: :streams

    # GET /api/v1/experiences/:experience_id/streams
    def index
    end

    # GET /api/v1/streams/:id
    def show
    end

    # POST /api/v1/experiences/:experience_id/streams
    def create
      if @stream.save
        render :show, status: :created, location: [:api, :v1, @stream]
      else
        render json: @stream.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/streams/:id
    def update
      if @stream.update(stream_params)
        render :show
      else
        render json: @stream.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/streams/:id
    def destroy
      @stream.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def stream_params
        strong_params = params.require(:stream).permit(
          *permitted_fields,
          :title,
          :description,
          :scheduled_at,
          :status,
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
  class Api::V1::StreamsController
  end
end
