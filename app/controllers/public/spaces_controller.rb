# Public::SpacesController - Handles public-facing space pages with root-level URLs
#
# This controller provides public access to space pages using clean root-level
# URLs (e.g., backstagepass.com/space-slug) for optimal branding and SEO.
# No authentication required.

class Public::SpacesController < Public::ApplicationController
  def show
    # Direct slug lookup with eager loading to prevent N+1 queries
    # Filter for published spaces FIRST to avoid slug conflicts
    @space = Space.published.friendly
      .includes(:team, {experiences: [:streams, :access_grants]}, :access_passes, :access_grants)
      .find(params[:space_slug])

    # Load related data for public display (already eager loaded)
    if @space.respond_to?(:experiences)
      @experiences = @space.experiences.respond_to?(:published) ? @space.experiences.published : @space.experiences
    end
    @total_members = begin
      @space.total_members
    rescue
      0
    end
  end

  def index
    # Start with published spaces with eager loading
    @spaces = Space.published
      .includes(:team, {access_passes: []}, {experiences: [:streams]}, {access_grants: [:user]})

    # Apply filters if present
    @spaces = if params[:sort_by].present?
      case params[:sort_by]
      when "newest"
        @spaces.order(created_at: :desc)
      when "popular"
        @spaces.order(active_passes_count: :desc)
      when "price_low"
        @spaces.joins(:access_passes)
          .where(access_passes: {published: true})
          .group("spaces.id")
          .order("MIN(access_passes.price_cents) ASC")
      when "price_high"
        @spaces.joins(:access_passes)
          .where(access_passes: {published: true})
          .group("spaces.id")
          .order("MAX(access_passes.price_cents) DESC")
      else
        @spaces.order(:name)
      end
    else
      @spaces.order(created_at: :desc)
    end

    # Price range filtering
    if params[:min_price].present? || params[:max_price].present?
      @spaces = @spaces.joins(:access_passes).where(access_passes: {published: true})

      if params[:min_price].present?
        min_cents = (params[:min_price].to_f * 100).to_i
        @spaces = @spaces.where("access_passes.price_cents >= ?", min_cents)
      end

      if params[:max_price].present?
        max_cents = (params[:max_price].to_f * 100).to_i
        @spaces = @spaces.where("access_passes.price_cents <= ?", max_cents)
      end

      @spaces = @spaces.distinct
    end

    # Search by name or description
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @spaces = @spaces.where("spaces.name ILIKE ? OR spaces.description ILIKE ?", search_term, search_term)
    end
  end
end
