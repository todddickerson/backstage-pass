class Account::SpacesController < Account::ApplicationController
  include DualIdFinder

  before_action :set_team
  before_action :set_space, only: [:show, :edit, :update, :destroy]
  before_action :build_space, only: [:new, :create]

  # GET /account/teams/:team_id/spaces
  # GET /account/teams/:team_id/spaces.json
  def index
    @spaces = @team.spaces
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

  def set_team
    team_id = params[:team_id] || @space&.team_id
    Rails.logger.debug "🔍 SET_TEAM: params[:team_id]=#{params[:team_id]}, @space&.team_id=#{@space&.team_id}, resolved team_id=#{team_id}"
    @team = current_user.teams.find_by(id: team_id) || current_user.teams.first
    Rails.logger.debug "🔍 SET_TEAM: @team=#{@team&.id} (#{@team&.name})"
  end

  def set_space
    Rails.logger.debug "🔍 SET_SPACE: Looking for space #{params[:id]} in team #{@team&.id}"
    @space = @team.spaces.find_by_any_id(params[:id])
    Rails.logger.debug "🔍 SET_SPACE: Found space #{@space.id}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "🔍 SET_SPACE ERROR: #{e.message}"
    flash[:error] = "Space not found"
    redirect_to [:account, @team, :spaces]
  end

  def build_space
    @space = @team.spaces.build(space_params) if params[:space]
    @space ||= @team.spaces.build
  end

  def space_params
    params.require(:space).permit(:name, :description, :slug, :published)
  end

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
