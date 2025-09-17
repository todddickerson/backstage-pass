class HealthController < ApplicationController
  skip_before_action :authenticate_user!, if: :devise_controller?

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
end
