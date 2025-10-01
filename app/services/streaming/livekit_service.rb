module Streaming
  class LivekitService
    attr_reader :room_service, :egress_service

    def initialize
      validate_environment!

      @room_service = LiveKit::RoomServiceClient.new(
        livekit_host,
        api_key: ENV["LIVEKIT_API_KEY"],
        api_secret: ENV["LIVEKIT_API_SECRET"]
      )

      @egress_service = LiveKit::EgressServiceClient.new(
        livekit_host,
        api_key: ENV["LIVEKIT_API_KEY"],
        api_secret: ENV["LIVEKIT_API_SECRET"]
      )
    end

    # Create a LiveKit room for streaming
    def create_room(stream)
      room_name = stream.room_name

      room = room_service.create_room(
        name: room_name,
        empty_timeout: 10 * 60, # 10 minutes
        max_participants: 500,
        metadata: {
          stream_id: stream.id,
          experience_id: stream.experience.id,
          space_id: stream.experience.space.id,
          team_id: stream.experience.space.team.id
        }.to_json
      )

      # Update stream with room info if we have those fields
      if stream.respond_to?(:livekit_room_name=)
        stream.update!(
          livekit_room_name: room.name,
          livekit_room_sid: room.sid
        )
      end

      room
    end

    # Generate access token for participant
    def generate_access_token(stream, user, permissions = {})
      room_name = stream.room_name

      # Determine participant identity
      identity = "user_#{user.id}"
      participant_name = user.name || user.email.split("@").first

      # Default permissions based on user role
      default_permissions = if stream.can_broadcast?(user)
        {
          can_publish: true,
          can_subscribe: true,
          can_publish_data: true,
          can_update_metadata: true
        }
      else
        {
          can_publish: false,
          can_subscribe: true,
          can_publish_data: false,
          can_update_metadata: false
        }
      end

      # Merge with custom permissions
      final_permissions = default_permissions.merge(permissions)

      # Create video grants (using camelCase as per gem API)
      video_grant = LiveKit::VideoGrant.new(
        roomJoin: true,
        room: room_name,
        canPublish: final_permissions[:can_publish],
        canSubscribe: final_permissions[:can_subscribe],
        canPublishData: final_permissions[:can_publish_data],
        canUpdateOwnMetadata: final_permissions[:can_update_metadata]
      )

      # Generate token
      token = LiveKit::AccessToken.new(
        api_key: ENV["LIVEKIT_API_KEY"],
        api_secret: ENV["LIVEKIT_API_SECRET"],
        identity: identity,
        name: participant_name,
        ttl: 24 * 60 * 60 # 24 hours
      )

      token.video_grant = video_grant

      token.to_jwt
    end

    # Get room participants
    def get_room_participants(stream)
      room_name = stream.room_name

      response = room_service.list_participants(room: room_name)
      response.participants
    end

    # Remove participant from room
    def remove_participant(stream, user_id)
      room_name = stream.room_name
      identity = "user_#{user_id}"

      room_service.remove_participant(
        room: room_name,
        identity: identity
      )
    end

    # Mute participant
    def mute_participant(stream, user_id, muted: true)
      room_name = stream.room_name
      identity = "user_#{user_id}"

      room_service.mute_published_track(
        room: room_name,
        identity: identity,
        muted: muted
      )
    end

    # Update room metadata
    def update_room_metadata(stream, metadata)
      room_name = stream.room_name

      room_service.update_room_metadata(
        room: room_name,
        metadata: metadata.to_json
      )
    end

    # Start recording (simplified for mobile focus)
    def start_recording(stream)
      room_name = stream.room_name

      # Basic recording setup - can be enhanced later
      egress_service.start_room_composite_egress(
        room_name: room_name,
        layout: "speaker-dark",
        file_output: {
          filepath: "recordings/#{stream.id}/#{Time.current.to_i}.mp4"
        }
      )
    rescue => e
      Rails.logger.error "Failed to start recording: #{e.message}"
      nil
    end

    # Stop recording
    def stop_recording(egress_id)
      egress_service.stop_egress(egress_id: egress_id)
    rescue => e
      Rails.logger.error "Failed to stop recording: #{e.message}"
      nil
    end

    # Delete room
    def delete_room(stream)
      room_name = stream.room_name
      room_service.delete_room(room: room_name)
    rescue => e
      Rails.logger.error "Failed to delete room: #{e.message}"
      nil
    end

    # Get room info
    def get_room_info(stream)
      room_name = stream.room_name
      response = room_service.list_rooms(names: [room_name])
      response.rooms.first
    rescue => e
      Rails.logger.error "Failed to get room info: #{e.message}"
      nil
    end

    # Generate connection info for mobile apps
    def generate_mobile_connection_info(stream, user, platform: "mobile")
      room_name = stream.room_name

      # Generate access token
      access_token = generate_access_token(stream, user)

      # Room URL for mobile SDKs
      room_url = ENV["LIVEKIT_URL"] || ENV["LIVEKIT_HOST"]

      # Mobile-specific configuration
      mobile_config = {
        # iOS/Android SDK configuration
        adaptiveStream: true,
        dynacast: true,
        publishMode: stream.can_broadcast?(user) ? "all" : "none",
        subscribeMode: "all",

        # Mobile optimizations
        reconnectPolicy: {
          nextRetryDelayFunc: "exponential",
          maxRetryDelay: 30000,
          maxRetries: 5
        },

        # Video configuration for mobile
        video: {
          resolution: {
            width: 1280,
            height: 720
          },
          frameRate: 30,
          bitrate: 2000000, # 2 Mbps
          codec: "h264"
        },

        # Audio configuration
        audio: {
          bitrate: 128000, # 128 kbps
          codec: "opus",
          sampleRate: 48000
        },

        # Background/PiP support
        backgroundMode: {
          enabled: true,
          audioOnly: true
        },

        pictureInPicture: {
          enabled: true,
          aspectRatio: "16:9"
        }
      }

      {
        room_url: room_url,
        access_token: access_token,
        room_name: room_name,
        participant_identity: "user_#{user.id}",
        participant_name: user.name || user.email.split("@").first,
        mobile_config: mobile_config,
        can_publish: stream.can_broadcast?(user),
        can_subscribe: true
      }
    end

    private

    def livekit_host
      ENV["LIVEKIT_URL"] || ENV["LIVEKIT_HOST"] || "wss://backstagepass-yl6ukwtf.livekit.cloud"
    end

    def validate_environment!
      required_vars = %w[LIVEKIT_API_KEY LIVEKIT_API_SECRET]
      missing_vars = required_vars.select { |var| ENV[var].blank? }

      if missing_vars.any?
        raise "Missing LiveKit environment variables: #{missing_vars.join(", ")}"
      end

      # Warn if no URL is set
      unless ENV["LIVEKIT_URL"] || ENV["LIVEKIT_HOST"]
        Rails.logger.warn "No LIVEKIT_URL or LIVEKIT_HOST set, using default"
      end
    end
  end
end
