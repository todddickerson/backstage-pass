# Public::AccessPassesController - Handles public-facing access pass sales pages
# 
# This controller provides public sales pages for access passes using clean nested
# URLs (e.g., backstagepass.com/space-slug/access-pass-slug) for optimal marketing.
# No authentication required for viewing, but purchase requires sign-in.

class Public::AccessPassesController < Public::ApplicationController

  def show
    # Find the space first
    @space = Space.friendly.find(params[:space_slug])
    
    # Ensure the space is published
    unless @space.published?
      raise ActiveRecord::RecordNotFound, "Space not found or not published"
    end
    
    # Find the access pass for this space
    @access_pass = @space.access_passes.friendly.find(params[:access_pass_slug])
    
    # Ensure the access pass is available for purchase
    unless @access_pass.available?
      raise ActiveRecord::RecordNotFound, "Access pass not available"
    end
    
    # Load pricing and features
    @pricing_tiers = @access_pass.pricing_tiers if @access_pass.respond_to?(:pricing_tiers)
    @included_experiences = @access_pass.included_experiences if @access_pass.respond_to?(:included_experiences)
  end
  
  # Purchase action - requires authentication via Devise or passwordless OTP
  def purchase
    # This will be handled by a separate checkout flow
    # For now, redirect to sign-in if not authenticated
    unless user_signed_in?
      session[:after_sign_in_path] = request.fullpath
      redirect_to new_user_session_path, alert: "Please sign in to purchase"
      return
    end
    
    # TODO: Implement Stripe checkout flow
  end
end
