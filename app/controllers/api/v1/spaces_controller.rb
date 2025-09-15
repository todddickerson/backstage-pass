# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::SpacesController < Api::V1::ApplicationController
    account_load_and_authorize_resource :space, through: :team, through_association: :spaces

    # GET /api/v1/teams/:team_id/spaces
    def index
    end

    # GET /api/v1/spaces/:id
    def show
    end

    # POST /api/v1/teams/:team_id/spaces
    def create
      if @space.save
        render :show, status: :created, location: [:api, :v1, @space]
      else
        render json: @space.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/spaces/:id
    def update
      if @space.update(space_params)
        render :show
      else
        render json: @space.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/spaces/:id
    def destroy
      @space.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def space_params
        strong_params = params.require(:space).permit(
          *permitted_fields,
          :name,
          :description,
          :slug,
          :published,
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
  class Api::V1::SpacesController
  end
end
