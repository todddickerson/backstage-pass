class Public::ApplicationController < ApplicationController
  layout "public"

  # Skip authentication for public routes
  skip_before_action :authenticate_user!, raise: false

  # Public routes don't need team context
  skip_before_action :set_current_team, raise: false

  private

  # current_user is handled by Devise automatically

  # Override current_team since public routes don't have team context
  def current_team
    nil
  end
end
