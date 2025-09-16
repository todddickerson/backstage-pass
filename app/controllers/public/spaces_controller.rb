# Public::SpacesController - Handles public-facing space pages with root-level URLs
#
# This controller provides public access to space pages using clean root-level
# URLs (e.g., backstagepass.com/space-slug) for optimal branding and SEO.
# No authentication required.

class Public::SpacesController < Public::ApplicationController

  def show
    # Direct slug lookup since we're using root-level routes
    @space = Space.friendly.find(params[:space_slug])
    
    # Ensure the space is published for public viewing
    unless @space.published?
      raise ActiveRecord::RecordNotFound, "Space not found or not published"
    end

    # Load related data for public display
    @experiences = @space.experiences if @space.respond_to?(:experiences)
    @total_members = begin
      @space.total_members
    rescue
      0
    end
  end

  def index
    @spaces = Space.published.includes(:team, :experiences)
  end
end
