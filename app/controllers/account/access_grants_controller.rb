class Account::AccessGrantsController < Account::ApplicationController
  account_load_and_authorize_resource :access_grant, through: :team, through_association: :access_grants

  # GET /account/teams/:team_id/access_grants
  # GET /account/teams/:team_id/access_grants.json
  def index
    delegate_json_to_api
  end

  # GET /account/access_grants/:id
  # GET /account/access_grants/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/teams/:team_id/access_grants/new
  def new
  end

  # GET /account/access_grants/:id/edit
  def edit
  end

  # POST /account/teams/:team_id/access_grants
  # POST /account/teams/:team_id/access_grants.json
  def create
    respond_to do |format|
      if @access_grant.save
        format.html { redirect_to [:account, @access_grant], notice: I18n.t("access_grants.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @access_grant] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @access_grant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/access_grants/:id
  # PATCH/PUT /account/access_grants/:id.json
  def update
    respond_to do |format|
      if @access_grant.update(access_grant_params)
        format.html { redirect_to [:account, @access_grant], notice: I18n.t("access_grants.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @access_grant] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @access_grant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/access_grants/:id
  # DELETE /account/access_grants/:id.json
  def destroy
    @access_grant.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @team, :access_grants], notice: I18n.t("access_grants.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    assign_date_and_time(strong_params, :expires_at)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
