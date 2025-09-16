class Account::Billing::PurchasesController < Account::ApplicationController
  account_load_and_authorize_resource :purchase, through: :team, through_association: :billing_purchases

  # GET /account/teams/:team_id/billing/purchases
  # GET /account/teams/:team_id/billing/purchases.json
  def index
    delegate_json_to_api
  end

  # GET /account/billing/purchases/:id
  # GET /account/billing/purchases/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/teams/:team_id/billing/purchases/new
  def new
  end

  # GET /account/billing/purchases/:id/edit
  def edit
  end

  # POST /account/teams/:team_id/billing/purchases
  # POST /account/teams/:team_id/billing/purchases.json
  def create
    respond_to do |format|
      if @purchase.save
        format.html { redirect_to [:account, @purchase], notice: I18n.t("billing/purchases.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @purchase] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/billing/purchases/:id
  # PATCH/PUT /account/billing/purchases/:id.json
  def update
    respond_to do |format|
      if @purchase.update(purchase_params)
        format.html { redirect_to [:account, @purchase], notice: I18n.t("billing/purchases.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @purchase] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/billing/purchases/:id
  # DELETE /account/billing/purchases/:id.json
  def destroy
    @purchase.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @team, :billing_purchases], notice: I18n.t("billing/purchases.notifications.destroyed") }
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
