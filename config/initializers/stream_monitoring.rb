# Stream Monitoring - Auto-end streams after timeout or broadcaster disconnect
#
# This initializer starts a recurring background job that monitors live streams
# and automatically ends them if:
# - Stream exceeds 8 hours (safety timeout)
# - Broadcaster disconnects for > 5 minutes
# - No viewers for > 1 hour (cost savings)

Rails.application.config.after_initialize do
  # Only start monitoring in non-test environments and when Sidekiq is available
  if defined?(Sidekiq) && !Rails.env.test?
    # Start the monitoring job (it will reschedule itself)
    MonitorLiveStreamsJob.set(wait: 1.minute).perform_later unless ENV["SKIP_STREAM_MONITORING"]

    Rails.logger.info "✅ Stream monitoring initialized (checks every 1 minute)"
  end
end
