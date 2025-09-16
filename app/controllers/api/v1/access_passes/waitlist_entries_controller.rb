# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::AccessPasses::WaitlistEntriesController < Api::V1::ApplicationController
    account_load_and_authorize_resource :waitlist_entry, through: :access_pass, through_association: :waitlist_entries

    # GET /api/v1/access_passes/:access_pass_id/waitlist_entries
    def index
    end

    # GET /api/v1/access_passes/waitlist_entries/:id
    def show
    end

    # POST /api/v1/access_passes/:access_pass_id/waitlist_entries
    def create
      if @waitlist_entry.save
        render :show, status: :created, location: [:api, :v1, @waitlist_entry]
      else
        render json: @waitlist_entry.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/access_passes/waitlist_entries/:id
    def update
      if @waitlist_entry.update(waitlist_entry_params)
        render :show
      else
        render json: @waitlist_entry.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/access_passes/waitlist_entries/:id
    def destroy
      @waitlist_entry.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def waitlist_entry_params
        strong_params = params.require(:access_passes_waitlist_entry).permit(
          *permitted_fields,
          :email,
          :first_name,
          :last_name,
          :answers,
          :status,
          :notes,
          :approved_at,
          :rejected_at,
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
  class Api::V1::AccessPasses::WaitlistEntriesController
  end
end
