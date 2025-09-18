class Account::Analytics::DailySnapshotsController < Account::ApplicationController
  account_load_and_authorize_resource :daily_snapshot, through: :team, through_association: :analytics_daily_snapshots

  # GET /account/teams/:team_id/analytics/daily_snapshots
  # GET /account/teams/:team_id/analytics/daily_snapshots.json
  def index
    delegate_json_to_api
  end

  # GET /account/analytics/daily_snapshots/:id
  # GET /account/analytics/daily_snapshots/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/teams/:team_id/analytics/daily_snapshots/new
  def new
  end

  # GET /account/analytics/daily_snapshots/:id/edit
  def edit
  end

  # POST /account/teams/:team_id/analytics/daily_snapshots
  # POST /account/teams/:team_id/analytics/daily_snapshots.json
  def create
    respond_to do |format|
      if @daily_snapshot.save
        format.html { redirect_to [:account, @daily_snapshot], notice: I18n.t("analytics/daily_snapshots.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @daily_snapshot] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @daily_snapshot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/analytics/daily_snapshots/:id
  # PATCH/PUT /account/analytics/daily_snapshots/:id.json
  def update
    respond_to do |format|
      if @daily_snapshot.update(daily_snapshot_params)
        format.html { redirect_to [:account, @daily_snapshot], notice: I18n.t("analytics/daily_snapshots.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @daily_snapshot] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @daily_snapshot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/analytics/daily_snapshots/:id
  # DELETE /account/analytics/daily_snapshots/:id.json
  def destroy
    @daily_snapshot.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @team, :analytics_daily_snapshots], notice: I18n.t("analytics/daily_snapshots.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    assign_date(strong_params, :date)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
