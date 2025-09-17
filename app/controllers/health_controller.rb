class HealthController < ApplicationController
  # Health checks should be publicly accessible - read-only operations only
  skip_before_action :prevent_parameter_pollution  # Safe for read-only health checks
  skip_after_action :audit_sensitive_actions       # No sensitive actions performed

  # Ensure only GET requests are allowed for security
  before_action :ensure_safe_method

  def show
    checks = {
      database: check_database,
      redis: check_redis,
      migrations: check_migrations
    }

    status = checks.values.all? ? :ok : :service_unavailable

    render json: {
      status: (status == :ok) ? "healthy" : "unhealthy",
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || "unknown",
      checks: checks
    }, status: status
  end

  private

  def check_database
    ActiveRecord::Base.connection.active?
    "ok"
  rescue => e
    Rails.logger.error "Health check database error: #{e.message}"
    "error"
  end

  def check_redis
    (Redis.new.ping == "PONG") ? "ok" : "error"
  rescue => e
    Rails.logger.error "Health check redis error: #{e.message}"
    "error"
  end

  def check_migrations
    ActiveRecord::Base.connection.migration_context.needs_migration? ? "pending" : "ok"
  rescue => e
    Rails.logger.error "Health check migrations error: #{e.message}"
    "error"
  end

  def ensure_safe_method
    unless request.get?
      render json: {error: "Method not allowed"}, status: :method_not_allowed
    end
  end
end
