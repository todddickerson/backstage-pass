# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::Analytics::DailySnapshotsController < Api::V1::ApplicationController
    account_load_and_authorize_resource :daily_snapshot, through: :team, through_association: :analytics_daily_snapshots

    # GET /api/v1/teams/:team_id/analytics/daily_snapshots
    def index
    end

    # GET /api/v1/analytics/daily_snapshots/:id
    def show
    end

    # POST /api/v1/teams/:team_id/analytics/daily_snapshots
    def create
      if @daily_snapshot.save
        render :show, status: :created, location: [:api, :v1, @daily_snapshot]
      else
        render json: @daily_snapshot.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/analytics/daily_snapshots/:id
    def update
      if @daily_snapshot.update(daily_snapshot_params)
        render :show
      else
        render json: @daily_snapshot.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/analytics/daily_snapshots/:id
    def destroy
      @daily_snapshot.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def daily_snapshot_params
        strong_params = params.require(:analytics_daily_snapshot).permit(
          *permitted_fields,
          :date,
          :space_id,
          :total_revenue_cents,
          :purchases_count,
          :active_passes_count,
          :stream_views,
          :chat_messages,
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
  class Api::V1::Analytics::DailySnapshotsController
  end
end
