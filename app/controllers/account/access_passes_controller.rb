class Account::AccessPassesController < Account::ApplicationController
  account_load_and_authorize_resource :access_pass, through: :space, through_association: :access_passes

  # GET /account/spaces/:space_id/access_passes
  # GET /account/spaces/:space_id/access_passes.json
  def index
    delegate_json_to_api
  end

  # GET /account/access_passes/:id
  # GET /account/access_passes/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/spaces/:space_id/access_passes/new
  def new
  end

  # GET /account/access_passes/:id/edit
  def edit
  end

  # POST /account/spaces/:space_id/access_passes
  # POST /account/spaces/:space_id/access_passes.json
  def create
    respond_to do |format|
      if @access_pass.save
        format.html { redirect_to [:account, @access_pass], notice: I18n.t("access_passes.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @access_pass] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @access_pass.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/access_passes/:id
  # PATCH/PUT /account/access_passes/:id.json
  def update
    respond_to do |format|
      if @access_pass.update(access_pass_params)
        format.html { redirect_to [:account, @access_pass], notice: I18n.t("access_passes.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @access_pass] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @access_pass.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/access_passes/:id
  # DELETE /account/access_passes/:id.json
  def destroy
    @access_pass.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @space, :access_passes], notice: I18n.t("access_passes.notifications.destroyed") }
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
