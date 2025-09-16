class Public::CreatorProfilesController < Public::ApplicationController
  # Public controller for @username routes - no authentication needed
  
  def show
    @creator_profile = Creators::Profile.find_by!(username: params[:username])
    @space = @creator_profile.primary_space
    
    # Redirect to space if it exists and is published
    if @space&.published?
      redirect_to public_space_path(@space.slug)
    else
      # Show coming soon page or 404 if creator hasn't set up space yet
      render :coming_soon
    end
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end
  
  private
  
  def set_current_user
    # Override to avoid authentication redirects for public routes
    super if user_signed_in?
  end
end