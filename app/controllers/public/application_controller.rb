class Public::ApplicationController < ApplicationController
  layout "public"
  
  # Skip authentication for public routes
  skip_before_action :authenticate_user!, raise: false
  
  # Public routes don't need team context
  skip_before_action :set_current_team, raise: false

  private

  # Override current_user to handle anonymous users
  def current_user
    super if user_signed_in?
  end

  # Override current_team since public routes don't have team context
  def current_team
    nil
  end
end
