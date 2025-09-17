# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::ExperiencesController < Api::V1::ApplicationController
    account_load_and_authorize_resource :experience, through: :space, through_association: :experiences

    before_action :preload_associations, only: [:index, :show]

    # GET /api/v1/spaces/:space_id/experiences
    def index
    end

    # GET /api/v1/experiences/:id
    def show
    end

    # POST /api/v1/spaces/:space_id/experiences
    def create
      if @experience.save
        render :show, status: :created, location: [:api, :v1, @experience]
      else
        render json: @experience.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/experiences/:id
    def update
      if @experience.update(experience_params)
        render :show
      else
        render json: @experience.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/experiences/:id
    def destroy
      @experience.destroy
    end

    private

    def preload_associations
      # Optimize queries by eager loading commonly accessed associations
      if action_name == "index" && @experiences
        @experiences = @experiences.includes(:space, :streams, :access_grants)
      elsif action_name == "show" && @experience
        # For single experience, load comprehensive associations for detailed view
        @experience = Experience.includes(
          :space,
          {streams: [:streaming_chat_rooms]},
          {access_grants: [:user, :access_pass]}
        ).find(@experience.id)
      end
    end

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def experience_params
        strong_params = params.require(:experience).permit(
          *permitted_fields,
          :name,
          :description,
          :experience_type,
          :price_cents,
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
  class Api::V1::ExperiencesController
  end
end
