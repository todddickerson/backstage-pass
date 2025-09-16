# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::AccessPassesController < Api::V1::ApplicationController
    account_load_and_authorize_resource :access_pass, through: :space, through_association: :access_passes

    # GET /api/v1/spaces/:space_id/access_passes
    def index
    end

    # GET /api/v1/access_passes/:id
    def show
    end

    # POST /api/v1/spaces/:space_id/access_passes
    def create
      if @access_pass.save
        render :show, status: :created, location: [:api, :v1, @access_pass]
      else
        render json: @access_pass.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/access_passes/:id
    def update
      if @access_pass.update(access_pass_params)
        render :show
      else
        render json: @access_pass.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/access_passes/:id
    def destroy
      @access_pass.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def access_pass_params
        strong_params = params.require(:access_pass).permit(
          *permitted_fields,
          :name,
          :description,
          :pricing_type,
          :price_cents,
          :stock_limit,
          :waitlist_enabled,
          :published,
          :slug,
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
  class Api::V1::AccessPassesController
  end
end
