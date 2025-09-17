# Public::SpacesController - Handles public-facing space pages with root-level URLs
#
# This controller provides public access to space pages using clean root-level
# URLs (e.g., backstagepass.com/space-slug) for optimal branding and SEO.
# No authentication required.

class Public::SpacesController < Public::ApplicationController
  def show
    # Direct slug lookup with eager loading to prevent N+1 queries
    @space = Space.friendly
      .includes(
        :team,
        {experiences: [:streams, :access_grants]},
        :access_passes,
        :access_grants
      )
      .find(params[:space_slug])

    # Ensure the space is published for public viewing
    unless @space.published?
      raise ActiveRecord::RecordNotFound, "Space not found or not published"
    end

    # Load related data for public display (already eager loaded)
    @experiences = @space.experiences.published if @space.respond_to?(:experiences)
    @total_members = begin
      @space.total_members
    rescue
      0
    end
  end

  def index
    # Eager load all necessary associations to prevent N+1 queries
    @spaces = Space.published
      .includes(:team, :access_passes, experiences: [:streams], access_grants: [:user])
      .order(:name)
  end
end
