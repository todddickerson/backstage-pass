class Account::SpacesController < Account::ApplicationController
  account_load_and_authorize_resource :space, through: :team, through_association: :spaces

  # GET /account/teams/:team_id/spaces
  # GET /account/teams/:team_id/spaces.json
  def index
    delegate_json_to_api
  end

  # GET /account/spaces/:id
  # GET /account/spaces/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/teams/:team_id/spaces/new
  def new
  end

  # GET /account/spaces/:id/edit
  def edit
  end

  # POST /account/teams/:team_id/spaces
  # POST /account/teams/:team_id/spaces.json
  def create
    respond_to do |format|
      if @space.save
        format.html { redirect_to [:account, @space], notice: I18n.t("spaces.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @space] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @space.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/spaces/:id
  # PATCH/PUT /account/spaces/:id.json
  def update
    respond_to do |format|
      if @space.update(space_params)
        format.html { redirect_to [:account, @space], notice: I18n.t("spaces.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @space] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @space.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/spaces/:id
  # DELETE /account/spaces/:id.json
  def destroy
    @space.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @team, :spaces], notice: I18n.t("spaces.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
