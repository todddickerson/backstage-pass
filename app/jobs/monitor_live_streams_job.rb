class MonitorLiveStreamsJob < ApplicationJob
  queue_as :default

  # Run this job every 1 minute to monitor live streams
  def perform
    Stream.live.find_each do |stream|
      check_stream_health(stream)
    end

    # Reschedule for next run (every 1 minute)
    MonitorLiveStreamsJob.set(wait: 1.minute).perform_later
  rescue => e
    Rails.logger.error "MonitorLiveStreamsJob failed: #{e.message}"
    # Still reschedule even on error
    MonitorLiveStreamsJob.set(wait: 1.minute).perform_later
  end

  private

  def check_stream_health(stream)
    # Check 1: Timeout (auto-end after 8 hours)
    if stream.started_at && stream.started_at < 8.hours.ago
      end_stream_with_reason(stream, "Stream exceeded maximum duration (8 hours)")
      return
    end

    # Check 2: No broadcaster present (check LiveKit room)
    unless broadcaster_present?(stream)
      # Grace period: Only end if no broadcaster for 5 minutes
      if stream.last_broadcaster_seen_at && stream.last_broadcaster_seen_at < 5.minutes.ago
        end_stream_with_reason(stream, "Broadcaster disconnected")
        return
      elsif stream.last_broadcaster_seen_at.nil?
        # First check - set timestamp
        stream.update_column(:last_broadcaster_seen_at, Time.current)
      end
    else
      # Broadcaster is present - reset grace period
      stream.update_column(:last_broadcaster_seen_at, Time.current)
    end

    # Check 3: No viewers for extended period (1 hour)
    if stream.started_at && stream.started_at < 1.hour.ago
      viewer_count = get_viewer_count(stream)
      if viewer_count.zero?
        end_stream_with_reason(stream, "No viewers for 1 hour")
      end
    end
  end

  def broadcaster_present?(stream)
    livekit_service = Streaming::LivekitService.new
    participants = livekit_service.get_room_participants(stream)

    return false if participants.nil? || participants.empty?

    # Check if any participant has broadcast permissions
    # For now, check if room has ANY participants (broadcaster would be first)
    participants.any?
  rescue => e
    Rails.logger.error "Failed to check broadcaster presence: #{e.message}"
    true # Assume present on error to avoid premature ending
  end

  def get_viewer_count(stream)
    livekit_service = Streaming::LivekitService.new
    participants = livekit_service.get_room_participants(stream)
    participants&.length || 0
  rescue => e
    Rails.logger.error "Failed to get viewer count: #{e.message}"
    1 # Assume viewers present on error
  end

  def end_stream_with_reason(stream, reason)
    Rails.logger.info "Auto-ending stream #{stream.id}: #{reason}"

    stream.update!(
      status: "ended",
      ended_at: Time.current
    )

    # Clean up LiveKit room
    begin
      livekit_service = Streaming::LivekitService.new
      livekit_service.delete_room(stream.room_name)
    rescue => e
      Rails.logger.warn "Failed to delete LiveKit room: #{e.message}"
    end

    # Notify broadcaster (optional)
    # StreamMailer.stream_ended(stream, reason).deliver_later
  end
end
