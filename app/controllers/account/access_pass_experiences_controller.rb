class Account::AccessPassExperiencesController < Account::ApplicationController
  account_load_and_authorize_resource :access_pass_experience, through: :access_pass, through_association: :access_pass_experiences

  # GET /account/access_passes/:access_pass_id/access_pass_experiences
  # GET /account/access_passes/:access_pass_id/access_pass_experiences.json
  def index
    delegate_json_to_api
  end

  # GET /account/access_pass_experiences/:id
  # GET /account/access_pass_experiences/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/access_passes/:access_pass_id/access_pass_experiences/new
  def new
  end

  # GET /account/access_pass_experiences/:id/edit
  def edit
  end

  # POST /account/access_passes/:access_pass_id/access_pass_experiences
  # POST /account/access_passes/:access_pass_id/access_pass_experiences.json
  def create
    respond_to do |format|
      if @access_pass_experience.save
        format.html { redirect_to [:account, @access_pass_experience], notice: I18n.t("access_pass_experiences.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @access_pass_experience] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @access_pass_experience.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/access_pass_experiences/:id
  # PATCH/PUT /account/access_pass_experiences/:id.json
  def update
    respond_to do |format|
      if @access_pass_experience.update(access_pass_experience_params)
        format.html { redirect_to [:account, @access_pass_experience], notice: I18n.t("access_pass_experiences.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @access_pass_experience] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @access_pass_experience.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/access_pass_experiences/:id
  # DELETE /account/access_pass_experiences/:id.json
  def destroy
    @access_pass_experience.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @access_pass, :access_pass_experiences], notice: I18n.t("access_pass_experiences.notifications.destroyed") }
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
