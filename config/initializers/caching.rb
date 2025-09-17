# Caching configuration for Backstage Pass
# Performance optimization settings

# Configure cache key versioning
Rails.application.config.cache_versioning = true

# Cache configuration for different environments
Rails.application.config.cache_store = if Rails.env.production?
  # Production: Use Redis for distributed caching
  [:redis_cache_store, {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
    pool_size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
    pool_timeout: 5,
    expires_in: 1.hour,
    reconnect_attempts: 3,
    error_handler: ->(method:, returning:, exception:) {
      Rails.logger.error("Cache error: #{method} - #{exception.class}: #{exception.message}")
    }
  }]
elsif Rails.env.development?
  # Development: Use file store for consistency across restarts
  [:file_store, Rails.root.join("tmp", "cache")]
else
  # Test: Use memory store for speed
  [:memory_store, {size: 32.megabytes}]
end

# Cache key generation helpers
module CacheKeyHelper
  extend ActiveSupport::Concern

  class_methods do
    # Generate cache key for model collections
    def cache_key_for_collection(relation, extra_keys = [])
      [
        relation.model.name.downcase.pluralize,
        relation.maximum(:updated_at)&.to_i,
        relation.count,
        *extra_keys
      ].compact.join("/")
    end

    # Generate cache key for user-specific content
    def cache_key_for_user(user, resource, extra_keys = [])
      [
        "user_#{user.id}",
        resource.class.name.downcase,
        resource.cache_key_with_version,
        *extra_keys
      ].compact.join("/")
    end
  end
end

# Include in ActiveRecord models
ActiveRecord::Base.include(CacheKeyHelper)

# Fragment cache configuration
class ActionController::Base
  # Enable automatic fragment caching in views
  def self.cache_fragments(*actions)
    before_action :setup_fragment_caching, only: actions
  end

  private

  def setup_fragment_caching
    @cache_enabled = Rails.env.production? || Rails.env.development?
    @cache_expires_in = 30.minutes
  end
end
