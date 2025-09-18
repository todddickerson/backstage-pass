# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::AccessPassExperiencesController < Api::V1::ApplicationController
    account_load_and_authorize_resource :access_pass_experience, through: :access_pass, through_association: :access_pass_experiences

    # GET /api/v1/access_passes/:access_pass_id/access_pass_experiences
    def index
    end

    # GET /api/v1/access_pass_experiences/:id
    def show
    end

    # POST /api/v1/access_passes/:access_pass_id/access_pass_experiences
    def create
      if @access_pass_experience.save
        render :show, status: :created, location: [:api, :v1, @access_pass_experience]
      else
        render json: @access_pass_experience.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/access_pass_experiences/:id
    def update
      if @access_pass_experience.update(access_pass_experience_params)
        render :show
      else
        render json: @access_pass_experience.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/access_pass_experiences/:id
    def destroy
      @access_pass_experience.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def access_pass_experience_params
        strong_params = params.require(:access_pass_experience).permit(
          *permitted_fields,
          :experience,
          :experience_id,
          :included,
          :position,
          # 🚅 super scaffolding will insert new fields above this line.
          *permitted_arrays,
          # 🚅 super scaffolding will insert new arrays above this line.
        )

        process_params(strong_params)

        strong_params
      end

      def process_params(strong_params)
        # Convert experience_id to experience association if provided
        if strong_params[:experience_id].present?
          strong_params[:experience] = Experience.find(strong_params[:experience_id])
          strong_params.delete(:experience_id)
        end

        strong_params
      end
    end

    include StrongParameters
  end
else
  class Api::V1::AccessPassExperiencesController
  end
end
