# app/controllers/hotwire_native_controller.rb
class HotwireNativeController < ApplicationController
  # This is a public endpoint, no authentication needed

  # Serve platform-specific configuration
  def configuration
    platform = params[:platform].to_s.downcase
    
    unless %w[ios android].include?(platform)
      render json: { error: "Invalid platform" }, status: :not_found
      return
    end

    # Load configuration from public directory
    config_path = Rails.root.join("public", "hotwire-native-config", "#{platform}.json")
    
    if File.exist?(config_path)
      config = JSON.parse(File.read(config_path))
      
      # Add environment-specific settings
      config["settings"] ||= {}
      config["settings"]["base_url"] = request.base_url
      config["settings"]["environment"] = Rails.env
      config["settings"]["enable_debug_logging"] = Rails.env.development?
      
      render json: config
    else
      render json: { error: "Configuration not found" }, status: :not_found
    end
  end
end