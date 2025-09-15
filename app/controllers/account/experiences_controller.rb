class Account::ExperiencesController < Account::ApplicationController
  account_load_and_authorize_resource :experience, through: :space, through_association: :experiences

  # GET /account/spaces/:space_id/experiences
  # GET /account/spaces/:space_id/experiences.json
  def index
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

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
