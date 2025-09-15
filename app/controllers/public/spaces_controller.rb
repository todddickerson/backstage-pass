# Public::SpacesController - Handles public-facing space pages with slug-based URLs
# 
# This controller provides public access to space information using human-readable
# slug URLs for better SEO and user experience. No authentication required.

class Public::SpacesController < Public::ApplicationController
  include DualIdFinder

  def show
    @space = find_resource(Space, params[:space_slug], prefer_slug: true)
    
    # Ensure the space is published for public viewing
    unless @space.published?
      raise ActiveRecord::RecordNotFound, "Space not found or not published"
    end
    
    # Load related data for public display
    @experiences = @space.experiences.published if @space.respond_to?(:experiences)
    @total_members = @space.total_members
  end

  def index
    @spaces = Space.published.includes(:team, :experiences)
  end

  private

  def find_resource(model_class, id, prefer_slug: false, admin_context: false)
    super(model_class, id, prefer_slug: prefer_slug, admin_context: false)
  end
end