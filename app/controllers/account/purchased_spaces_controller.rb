class Account::PurchasedSpacesController < Account::ApplicationController
  # GET /account/purchased_spaces
  def index
    # Get all active access grants for the current user
    @access_grants = current_user.access_grants.active.includes(
      :access_pass,
      purchasable: [:team, { space: :team }, { experiences: :streams }]
    )

    # Group by space for cleaner display
    @purchased_spaces = @access_grants.map(&:space).uniq.compact

    # Get upcoming and live streams for these spaces
    @upcoming_streams = Stream.joins(experience: :space)
                             .where(experience: { spaces: { id: @purchased_spaces.map(&:id) } })
                             .where(status: [:scheduled, :live])
                             .where("scheduled_at > ? OR status = ?", Time.current, "live")
                             .includes(experience: [:space, :team])
                             .order(:scheduled_at)

    # Separate live and upcoming streams
    @live_streams = @upcoming_streams.where(status: :live)
    @scheduled_streams = @upcoming_streams.where(status: :scheduled)

    # Recently ended streams (last 7 days) for replay
    @recent_streams = Stream.joins(experience: :space)
                           .where(experience: { spaces: { id: @purchased_spaces.map(&:id) } })
                           .where(status: :ended)
                           .where("streams.updated_at > ?", 7.days.ago)
                           .includes(experience: [:space, :team])
                           .order("streams.updated_at DESC")
                           .limit(10)
  end

  # GET /account/purchased_spaces/:space_id
  def show
    @space = Space.find(params[:id])
    
    # Verify user has access to this space
    @access_grant = current_user.access_grants.active.find_by(purchasable: @space) ||
                   current_user.access_grants.active
                                .joins("JOIN experiences ON access_grants.purchasable_type = 'Experience' AND access_grants.purchasable_id = experiences.id")
                                .where(experiences: { space_id: @space.id })
                                .first

    unless @access_grant
      redirect_to account_purchased_spaces_path, 
                  alert: "You don't have access to this space"
      return
    end

    # Get all streams for this space
    @upcoming_streams = @space.experiences.joins(:streams)
                             .merge(Stream.where(status: [:scheduled, :live]))
                             .where("streams.scheduled_at > ? OR streams.status = ?", 
                                   Time.current, "live")
                             .order("streams.scheduled_at")

    @live_streams = @space.experiences.joins(:streams)
                         .merge(Stream.where(status: :live))

    @recent_streams = @space.experiences.joins(:streams)
                           .merge(Stream.where(status: :ended))
                           .where("streams.updated_at > ?", 7.days.ago)
                           .order("streams.updated_at DESC")
                           .limit(10)

    # Get all experiences in this space that user has access to
    @experiences = @space.experiences.includes(:access_passes, :streams)
  end

  private

  def ensure_user_has_purchases
    if current_user.access_grants.active.empty?
      redirect_to root_path, notice: "Browse spaces to purchase access"
    end
  end
end