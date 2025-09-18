class Public::WaitlistEntriesController < ApplicationController
  before_action :find_access_pass, only: [:new, :create]
  before_action :verify_waitlist_enabled, only: [:new, :create]

  # GET /:space_slug/:access_pass_slug/waitlist
  def new
    @waitlist_entry = @access_pass.waitlist_entries.build
    @custom_questions = @access_pass.parsed_custom_questions
  end

  # POST /:space_slug/:access_pass_slug/waitlist
  def create
    @waitlist_entry = @access_pass.waitlist_entries.build(waitlist_entry_params)
    @waitlist_entry.status = "pending"

    if @waitlist_entry.save
      redirect_to waitlist_success_path(@space.slug, @access_pass.slug),
        notice: "Thank you for joining the waitlist! We'll be in touch soon."
    else
      @custom_questions = @access_pass.parsed_custom_questions
      render :new, status: :unprocessable_entity
    end
  end

  # GET /:space_slug/:access_pass_slug/waitlist/success
  def success
    @access_pass = find_access_pass_for_success
    @space = @access_pass.space
  end

  private

  def find_access_pass
    @space = Space.find_by!(slug: params[:space_slug])
    @access_pass = @space.access_passes.find_by!(slug: params[:access_pass_slug])
  end

  def find_access_pass_for_success
    space = Space.find_by!(slug: params[:space_slug])
    space.access_passes.find_by!(slug: params[:access_pass_slug])
  end

  def verify_waitlist_enabled
    unless @access_pass.waitlist_enabled?
      redirect_to public_space_access_pass_path(@space.slug, @access_pass.slug),
        alert: "Waitlist is not available for this access pass."
    end
  end

  def waitlist_entry_params
    params.require(:access_passes_waitlist_entry).permit(
      :email, :first_name, :last_name, :answers
    )
  end

  def render_not_found
    render "public/shared/not_found", status: :not_found
  end

  def render_access_denied(message = "Access denied")
    render "public/shared/access_denied", status: :forbidden, locals: {message: message}
  end
end
