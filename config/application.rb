require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/bullet_train_oauth_scaffolder_support"

module UntitledApplication
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # See `config/locales/locales.yml` for a list of available locales.
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.available_locales = YAML.safe_load_file("config/locales/locales.yml", aliases: true).with_indifferent_access.dig(:locales).keys.map(&:to_sym)
    config.i18n.default_locale = config.i18n.available_locales.first
    config.i18n.fallbacks = [:en]

    BulletTrain::Api.set_configuration(self)

    # Security Configuration
    
    # Force SSL in production
    config.force_ssl = true if Rails.env.production?
    
    # Secure cookies
    config.session_store :cookie_store, 
      key: "_backstage_pass_session",
      secure: Rails.env.production?, # HTTPS only in production
      httponly: true, # Prevent JavaScript access
      same_site: :lax # CSRF protection
    
    # Security headers middleware
    config.middleware.use SecureHeaders::Middleware
    
    # Configure allowed hosts for DNS rebinding protection
    # In production, set this to your actual domain
    if Rails.env.production?
      config.hosts << "backstagepass.app"
      config.hosts << "www.backstagepass.app"
    else
      # Allow ngrok and local development
      config.hosts << /.*\.ngrok\.app/
      config.hosts << /.*\.ngrok-free\.app/
      config.hosts << "localhost"
    end
    
    # Set secure headers for ActionDispatch
    config.action_dispatch.default_headers = {
      "X-Frame-Options" => "SAMEORIGIN",
      "X-XSS-Protection" => "1; mode=block",
      "X-Content-Type-Options" => "nosniff",
      "X-Download-Options" => "noopen",
      "X-Permitted-Cross-Domain-Policies" => "none",
      "Referrer-Policy" => "strict-origin-when-cross-origin"
    }
    
    # Configure ActiveRecord encryption (for Rails 7+)
    # This will encrypt sensitive data at rest
    # Generate keys with: bin/rails db:encryption:init
    # config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    # config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    # config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]
    
    # Prevent timing attacks on CSRF tokens
    config.action_controller.default_protect_from_forgery = true
    
    # Log security events
    if Rails.env.production?
      config.log_tags = [:request_id, :remote_ip]
    end
  end
end
