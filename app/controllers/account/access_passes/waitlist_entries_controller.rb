class Account::AccessPasses::WaitlistEntriesController < Account::ApplicationController
  account_load_and_authorize_resource :waitlist_entry, through: :access_pass, through_association: :waitlist_entries, shallow: true

  # GET /account/access_passes/:access_pass_id/waitlist_entries
  # GET /account/access_passes/:access_pass_id/waitlist_entries.json
  def index
    delegate_json_to_api
  end

  # GET /account/access_passes/waitlist_entries/:id
  # GET /account/access_passes/waitlist_entries/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/access_passes/:access_pass_id/waitlist_entries/new
  def new
  end

  # GET /account/access_passes/waitlist_entries/:id/edit
  def edit
  end

  # POST /account/access_passes/:access_pass_id/waitlist_entries
  # POST /account/access_passes/:access_pass_id/waitlist_entries.json
  def create
    respond_to do |format|
      if @waitlist_entry.save
        format.html { redirect_to [:account, @waitlist_entry], notice: I18n.t("access_passes/waitlist_entries.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @waitlist_entry] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @waitlist_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/access_passes/waitlist_entries/:id
  # PATCH/PUT /account/access_passes/waitlist_entries/:id.json
  def update
    respond_to do |format|
      if @waitlist_entry.update(waitlist_entry_params)
        format.html { redirect_to [:account, @waitlist_entry], notice: I18n.t("access_passes/waitlist_entries.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @waitlist_entry] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @waitlist_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/access_passes/waitlist_entries/:id
  # DELETE /account/access_passes/waitlist_entries/:id.json
  def destroy
    @waitlist_entry.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @access_pass, :waitlist_entries], notice: I18n.t("access_passes/waitlist_entries.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  # POST /account/access_passes/waitlist_entries/:id/approve
  def approve
    @waitlist_entry ||= AccessPasses::WaitlistEntry.find(params[:id])
    if @waitlist_entry.pending?
      @waitlist_entry.status = "approved"
      @waitlist_entry.approved_at = Time.current

      if @waitlist_entry.save
        # Send approval email
        WaitlistMailer.approval_email(@waitlist_entry).deliver_later

        redirect_to [:account, @waitlist_entry], notice: I18n.t("access_passes/waitlist_entries.notifications.approved")
      else
        redirect_to [:account, @waitlist_entry], alert: I18n.t("access_passes/waitlist_entries.notifications.approval_failed")
      end
    else
      redirect_to [:account, @waitlist_entry], alert: I18n.t("access_passes/waitlist_entries.notifications.already_processed")
    end
  end

  # POST /account/access_passes/waitlist_entries/:id/reject
  def reject
    @waitlist_entry ||= AccessPasses::WaitlistEntry.find(params[:id])
    if @waitlist_entry.pending?
      @waitlist_entry.status = "rejected"
      @waitlist_entry.rejected_at = Time.current

      if @waitlist_entry.save
        # Send rejection email
        WaitlistMailer.rejection_email(@waitlist_entry).deliver_later

        redirect_to [:account, @waitlist_entry], notice: I18n.t("access_passes/waitlist_entries.notifications.rejected")
      else
        redirect_to [:account, @waitlist_entry], alert: I18n.t("access_passes/waitlist_entries.notifications.rejection_failed")
      end
    else
      redirect_to [:account, @waitlist_entry], alert: I18n.t("access_passes/waitlist_entries.notifications.already_processed")
    end
  end

  private

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    assign_date_and_time(strong_params, :approved_at)
    assign_date_and_time(strong_params, :rejected_at)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
