class Account::ExperiencesController < Account::ApplicationController
  before_action :set_space
  before_action :set_experience, only: [:show, :edit, :update, :destroy]
  before_action :build_experience, only: [:new, :create]

  # GET /account/spaces/:space_id/experiences
  # GET /account/spaces/:space_id/experiences.json
  def index
    @experiences = @space.experiences
    delegate_json_to_api
  end

  # GET /account/experiences/:id
  # GET /account/experiences/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/spaces/:space_id/experiences/new
  def new
  end

  # GET /account/experiences/:id/edit
  def edit
  end

  # POST /account/spaces/:space_id/experiences
  # POST /account/spaces/:space_id/experiences.json
  def create
    respond_to do |format|
      if @experience.save
        format.html { redirect_to [:account, @experience], notice: I18n.t("experiences.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @experience] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @experience.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/experiences/:id
  # PATCH/PUT /account/experiences/:id.json
  def update
    respond_to do |format|
      if @experience.update(experience_params)
        format.html { redirect_to [:account, @experience], notice: I18n.t("experiences.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @experience] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @experience.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/experiences/:id
  # DELETE /account/experiences/:id.json
  def destroy
    @experience.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @space, :experiences], notice: I18n.t("experiences.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  def set_space
    @space = current_user.teams.joins(:spaces).merge(Space.friendly).find_by(spaces: {id: params[:space_id]})&.spaces&.friendly&.find(params[:space_id])
    @space ||= current_user.teams.joins(:spaces).merge(Space.where(id: @experience&.space_id)).first&.spaces&.find_by(id: @experience&.space_id) if @experience
    @space ||= current_user.teams.first&.spaces&.first
  end

  def set_experience
    @experience = @space.experiences.find(params[:id])
  end

  def build_experience
    @experience = @space.experiences.build(experience_params) if params[:experience]
    @experience ||= @space.experiences.build
  end

  def experience_params
    return {} unless params[:experience]
    params.require(:experience).permit(:name, :description, :experience_type, :price_cents)
  end

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
