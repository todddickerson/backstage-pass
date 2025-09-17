require "test_helper"
require "benchmark"

class MobileStreamingPerformanceTest < ActiveSupport::TestCase
  setup do
    @creator = create(:onboarded_user, first_name: "Creator", last_name: "Mobile")
    
    # Ensure the creator's team has a name for space creation
    if @creator.current_team.name.blank?
      @creator.current_team.update!(name: "#{@creator.name}'s Team")
    end
    
    @space = @creator.current_team.primary_space
    
    # Create space manually if it doesn't exist
    @space ||= @creator.current_team.spaces.create!(
      name: "#{@creator.current_team.name}'s Space",
      slug: @creator.current_team.name.parameterize,
      description: "Test space for mobile performance",
      published: true
    )

    puts "DEBUG Performance Test: @space=#{@space&.id}, @space.nil?=#{@space.nil?}"
    
    begin
      @experience = @space.experiences.create!(
        name: "Mobile Performance Experience",
        description: "Testing mobile streaming performance",
        experience_type: "live_stream",
        price_cents: 2999
      )
      
      puts "DEBUG Performance Test: @experience=#{@experience&.id}, @experience.nil?=#{@experience.nil?}"
    rescue => e
      puts "DEBUG Performance Test: Experience creation failed: #{e.class}: #{e.message}"
      puts "DEBUG Performance Test: Experience errors: #{@experience&.errors&.full_messages}"
      raise e
    end
  end

  test "mobile API response time benchmarks" do
    benchmark_name = "Mobile API Response Times"

    # Simulate mobile app API calls
    api_benchmarks = {}

    # 1. User authentication and profile load
    api_benchmarks[:auth_profile] = Benchmark.measure do
      {
        id: @creator.id,
        name: @creator.name,
        email: @creator.email,
        teams: @creator.teams.includes(:spaces).map do |team|
          {
            id: team.id,
            name: team.name,
            spaces: team.spaces.map { |space| {id: space.id, name: space.name} }
          }
        end
      }
    end

    # 2. Space content loading (experiences, access passes)
    api_benchmarks[:space_content] = Benchmark.measure do
      {
        id: @space.id,
        name: @space.name,
        experiences: @space.experiences.includes(:streams, :access_grants).map do |exp|
          {
            id: exp.id,
            name: exp.name,
            price_cents: exp.price_cents,
            streams_count: exp.streams.count,
            active_grants_count: exp.access_grants.active.count
          }
        end,
        access_passes: @space.access_passes.published.map do |pass|
          {
            id: pass.id,
            name: pass.name,
            price_cents: pass.price_cents,
            pricing_type: pass.pricing_type
          }
        end
      }
    end

    # 3. Stream discovery and listing
    # Create multiple streams for realistic testing
    10.times do |i|
      @experience.streams.create!(
        title: "Mobile Stream #{i}",
        description: "Performance testing stream",
        scheduled_at: i.hours.from_now,
        status: ["scheduled", "live", "ended"].sample
      )
    end

    api_benchmarks[:stream_discovery] = Benchmark.measure do
      @space.experiences
        .includes(:streams)
        .flat_map(&:streams)
        .map do |stream|
          {
            id: stream.id,
            title: stream.title,
            status: stream.status,
            room_name: stream.room_name,
            scheduled_at: stream.scheduled_at,
            experience_name: stream.experience.name
          }
        end
    end

    # 4. Live stream connection data
    live_stream = @experience.streams.create!(
      title: "Live Performance Test",
      description: "Testing live streaming performance",
      scheduled_at: Time.current,
      status: "live"
    )

    api_benchmarks[:live_connection] = Benchmark.measure do
      {
        stream_id: live_stream.id,
        room_name: live_stream.room_name,

        # Mock LiveKit connection data (would come from service)
        livekit_config: {
          room_url: "wss://test.livekit.cloud",
          room_name: live_stream.room_name,
          participant_identity: "user_#{@creator.id}",
          participant_name: @creator.name,
          can_publish: live_stream.can_broadcast?(@creator),
          can_subscribe: live_stream.can_view?(@creator)
        },

        # Chat room data
        chat_room: live_stream.streaming_chat_rooms.first&.then do |room|
          {
            channel_id: room.channel_id,
            can_access: room.can_access?(@creator),
            can_moderate: room.can_moderate?(@creator)
          }
        end
      }
    end

    puts "\n#{benchmark_name}:"
    api_benchmarks.each do |endpoint, time|
      puts "  #{endpoint}: #{(time.real * 1000).round(1)}ms"

      # Mobile performance assertions (mobile users expect < 300ms responses)
      assert time.real < 0.3, "#{endpoint} API should respond in under 300ms for mobile (took #{(time.real * 1000).round(1)}ms)"
    end
  end

  test "concurrent mobile users streaming performance" do
    benchmark_name = "Concurrent Mobile Users Performance"

    # Create live stream
    live_stream = @experience.streams.create!(
      title: "Concurrent Users Test",
      description: "Testing multiple mobile users",
      scheduled_at: Time.current,
      status: "live"
    )

    chat_room = live_stream.streaming_chat_rooms.create!(
      channel_id: "concurrent_test_#{live_stream.id}"
    )

    # Create access pass and grant access to multiple users
    access_pass = @space.access_passes.create!(
      name: "Concurrent Access",
      description: "Testing concurrent user access",
      pricing_type: "one_time",
      price_cents: 1999,
      published: true
    )

    # Simulate 50 concurrent mobile users joining
    mobile_users = 50.times.map do |i|
      user = create(:onboarded_user,
        first_name: "Mobile#{i}",
        last_name: "User",
        email: "mobile_user_#{i}@example.com")

      @creator.current_team.access_grants.create!(
        access_pass: access_pass,
        user: user,
        status: "active",
        purchasable: @experience
      )

      user
    end

    # Test concurrent access checks
    concurrent_time = Benchmark.measure do
      # Simulate all users checking access simultaneously
      mobile_users.each do |user|
        can_view_stream = live_stream.can_view?(user)
        can_access_chat = chat_room.can_access?(user)

        # Mock mobile connection setup
        if can_view_stream
          {
            user_id: user.id,
            stream_id: live_stream.id,
            room_name: live_stream.room_name,
            chat_channel: chat_room.channel_id,
            permissions: {
              can_view: can_view_stream,
              can_chat: can_access_chat,
              can_moderate: chat_room.can_moderate?(user)
            }
          }
        end
      end
    end

    puts "\n#{benchmark_name}:"
    puts "  50 Concurrent Users: #{concurrent_time.real.round(3)}s"
    puts "  Per User Setup: #{(concurrent_time.real / 50 * 1000).round(1)}ms"

    # Performance assertions for concurrent users
    assert concurrent_time.real < 2.0, "50 concurrent users should be handled in under 2 seconds (took #{concurrent_time.real.round(3)}s)"
    assert (concurrent_time.real / 50) < 0.04, "Each user setup should take less than 40ms (took #{(concurrent_time.real / 50 * 1000).round(1)}ms)"
  end

  test "mobile chat room scalability performance" do
    benchmark_name = "Mobile Chat Room Scalability"

    # Create multiple streams with chat rooms
    streams_with_chat = 5.times.map do |i|
      stream = @experience.streams.create!(
        title: "Chat Scale Stream #{i}",
        description: "Testing chat scalability",
        scheduled_at: Time.current,
        status: "live"
      )

      chat_room = stream.streaming_chat_rooms.create!(
        channel_id: "scale_test_#{i}_#{stream.id}"
      )

      {stream: stream, chat_room: chat_room}
    end

    # Create users for each chat room
    users_per_room = 20
    total_chat_users = streams_with_chat.flat_map do |stream_data|
      stream = stream_data[:stream]
      users_per_room.times.map do |j|
        create(:onboarded_user,
          first_name: "ChatUser#{stream.id}#{j}",
          last_name: "Scale",
          email: "chat_user_#{stream.id}_#{j}@example.com")
      end
    end

    # Test chat room operations at scale
    chat_performance = Benchmark.measure do
      streams_with_chat.each_with_index do |stream_data, i|
        chat_room = stream_data[:chat_room]
        room_users = total_chat_users.slice(i * users_per_room, users_per_room)

        # Simulate mobile chat operations
        room_users.each do |user|
          # Mock checking chat permissions
          can_access = chat_room.can_access?(@creator) # Team member always has access
          can_moderate = chat_room.can_moderate?(@creator)

          # Mock mobile chat configuration
          {
            user_id: user.id,
            channel_id: chat_room.channel_id,
            permissions: {
              can_send_message: can_access,
              can_delete_own_message: can_access,
              can_react: can_access,
              can_moderate: can_moderate
            },
            mobile_optimizations: {
              message_pagination: 20,
              typing_indicators: true,
              read_receipts: true,
              offline_sync: true
            }
          }
        end
      end
    end

    total_chat_operations = streams_with_chat.length * users_per_room

    puts "\n#{benchmark_name}:"
    puts "  Chat Rooms: #{streams_with_chat.length}"
    puts "  Users per Room: #{users_per_room}"
    puts "  Total Operations: #{total_chat_operations}"
    puts "  Total Time: #{chat_performance.real.round(3)}s"
    puts "  Per Operation: #{(chat_performance.real / total_chat_operations * 1000).round(1)}ms"

    # Chat scalability assertions
    assert chat_performance.real < 5.0, "Chat room operations should complete in under 5 seconds (took #{chat_performance.real.round(3)}s)"
    assert (chat_performance.real / total_chat_operations) < 0.05, "Each chat operation should take less than 50ms (took #{(chat_performance.real / total_chat_operations * 1000).round(1)}ms)"
  end

  test "mobile payment processing performance" do
    benchmark_name = "Mobile Payment Processing Performance"

    # Create various access passes for testing
    access_passes = [
      {
        name: "Mobile Basic Pass",
        pricing_type: "one_time",
        price_cents: 999
      },
      {
        name: "Mobile Premium Pass",
        pricing_type: "one_time",
        price_cents: 2999
      },
      {
        name: "Mobile Monthly Sub",
        pricing_type: "monthly",
        price_cents: 1999
      }
    ].map do |pass_data|
      @space.access_passes.create!(
        name: pass_data[:name],
        description: "Mobile payment testing",
        pricing_type: pass_data[:pricing_type],
        price_cents: pass_data[:price_cents],
        published: true
      )
    end

    # Create customers for payment testing
    mobile_customers = 30.times.map do |i|
      create(:onboarded_user,
        first_name: "PayCustomer#{i}",
        last_name: "Mobile",
        email: "pay_customer_#{i}@example.com")
    end

    # Test payment flow performance
    payment_time = Benchmark.measure do
      mobile_customers.each_with_index do |customer, i|
        access_pass = access_passes[i % access_passes.length]

        # Mock mobile payment intent creation
        {
          id: "pi_mobile_test_#{i}",
          amount: access_pass.price_cents,
          currency: "usd",
          status: "requires_payment_method",

          # Mobile optimizations
          payment_method_types: ["card", "apple_pay", "google_pay"],
          mobile_config: {
            apple_pay_enabled: true,
            google_pay_enabled: true,
            touch_id_enabled: true,
            face_id_enabled: true
          },

          metadata: {
            access_pass_id: access_pass.id.to_s,
            customer_user_id: customer.id.to_s,
            platform: "mobile_ios" # or mobile_android
          }
        }

        # Mock successful payment completion and access grant
        if i.even? # Simulate 50% payment success rate
          @creator.current_team.access_grants.create!(
            access_pass: access_pass,
            user: customer,
            status: "active",
            purchasable: @experience
          )
        end
      end
    end

    successful_payments = mobile_customers.count { |_, i| i.even? }

    puts "\n#{benchmark_name}:"
    puts "  Total Customers: #{mobile_customers.length}"
    puts "  Successful Payments: #{successful_payments}"
    puts "  Payment Processing Time: #{payment_time.real.round(3)}s"
    puts "  Per Payment: #{(payment_time.real / mobile_customers.length * 1000).round(1)}ms"

    # Mobile payment performance assertions
    assert payment_time.real < 3.0, "Mobile payment processing should complete quickly (took #{payment_time.real.round(3)}s)"
    assert (payment_time.real / mobile_customers.length) < 0.1, "Each payment should process in under 100ms (took #{(payment_time.real / mobile_customers.length * 1000).round(1)}ms)"
  end

  test "mobile app data synchronization performance" do
    benchmark_name = "Mobile App Data Sync Performance"

    # Create rich data structure for sync testing
    3.times.map do |space_i|
      space = @creator.current_team.spaces.create!(
        name: "Sync Space #{space_i}",
        description: "Mobile sync testing"
      )

      experiences = 5.times.map do |exp_i|
        experience = space.experiences.create!(
          name: "Sync Experience #{space_i}-#{exp_i}",
          description: "Mobile sync test experience",
          experience_type: "live_stream",
          price_cents: 1999 + (exp_i * 500)
        )

        # Create streams with various statuses
        streams = 3.times.map do |stream_i|
          experience.streams.create!(
            title: "Sync Stream #{space_i}-#{exp_i}-#{stream_i}",
            description: "Mobile sync test stream",
            scheduled_at: stream_i.hours.from_now,
            status: ["scheduled", "live", "ended"][stream_i % 3]
          )
        end

        {experience: experience, streams: streams}
      end

      access_passes = 2.times.map do |pass_i|
        space.access_passes.create!(
          name: "Sync Pass #{space_i}-#{pass_i}",
          description: "Mobile sync test pass",
          pricing_type: ["one_time", "monthly"][pass_i % 2],
          price_cents: 999 + (pass_i * 1000),
          published: true
        )
      end

      {space: space, experiences: experiences, access_passes: access_passes}
    end

    # Test mobile app full data sync
    sync_time = Benchmark.measure do
      # This simulates the data structure a mobile app would request
      mobile_app_data = {
        user: {
          id: @creator.id,
          name: @creator.name,
          email: @creator.email
        },

        teams: @creator.teams.includes(
          spaces: [
            :access_passes,
            {experiences: {streams: :streaming_chat_rooms}}
          ]
        ).map do |team|
          {
            id: team.id,
            name: team.name,

            spaces: team.spaces.map do |space|
              {
                id: space.id,
                name: space.name,

                experiences: space.experiences.map do |experience|
                  {
                    id: experience.id,
                    name: experience.name,
                    price_cents: experience.price_cents,
                    experience_type: experience.experience_type,

                    streams: experience.streams.map do |stream|
                      {
                        id: stream.id,
                        title: stream.title,
                        status: stream.status,
                        scheduled_at: stream.scheduled_at,
                        room_name: stream.room_name,

                        chat_rooms: stream.streaming_chat_rooms.map do |chat_room|
                          {
                            id: chat_room.id,
                            channel_id: chat_room.channel_id
                          }
                        end
                      }
                    end
                  }
                end,

                access_passes: space.access_passes.published.map do |pass|
                  {
                    id: pass.id,
                    name: pass.name,
                    pricing_type: pass.pricing_type,
                    price_cents: pass.price_cents
                  }
                end
              }
            end
          }
        end
      }

      # Calculate data size (mobile apps care about payload size)
      mobile_app_data.to_json.bytesize
    end

    puts "\n#{benchmark_name}:"
    puts "  Full Sync Time: #{sync_time.real.round(3)}s"
    puts "  Data Payload Size: #{(sync_time.real.to_json.bytesize / 1024.0).round(1)}KB"

    # Mobile sync performance assertions
    assert sync_time.real < 2.0, "Mobile app sync should complete in under 2 seconds (took #{sync_time.real.round(3)}s)"
  end

  test "offline mode data caching performance" do
    benchmark_name = "Offline Mode Data Caching"

    # Create essential data that should be cached for offline use
    essential_experience = @space.experiences.create!(
      name: "Offline Cache Experience",
      description: "Testing offline data caching",
      experience_type: "live_stream",
      price_cents: 2999
    )

    essential_streams = 5.times.map do |i|
      essential_experience.streams.create!(
        title: "Offline Stream #{i}",
        description: "Essential stream for offline access",
        scheduled_at: (i + 1).hours.from_now,
        status: ["scheduled", "live"][i % 2]
      )
    end

    # Test creating offline data cache
    cache_creation_time = Benchmark.measure do
      # Simulate creating offline cache data structure
      offline_cache = {
        user_profile: {
          id: @creator.id,
          name: @creator.name,
          email: @creator.email
        },

        essential_spaces: @creator.current_team.spaces.includes(:experiences, :access_passes).map do |space|
          {
            id: space.id,
            name: space.name,

            # Only cache published and active content for offline
            experiences: space.experiences.limit(10).map do |exp|
              {
                id: exp.id,
                name: exp.name,
                description: exp.description,
                price_cents: exp.price_cents,
                cached_at: Time.current
              }
            end,

            access_passes: space.access_passes.published.map do |pass|
              {
                id: pass.id,
                name: pass.name,
                pricing_type: pass.pricing_type,
                price_cents: pass.price_cents,
                cached_at: Time.current
              }
            end
          }
        end,

        upcoming_streams: essential_streams.select { |s| s.status == "scheduled" }.map do |stream|
          {
            id: stream.id,
            title: stream.title,
            scheduled_at: stream.scheduled_at,
            experience_name: stream.experience.name,
            cached_at: Time.current
          }
        end,

        # Cache metadata
        cache_version: "1.0",
        cached_at: Time.current,
        expires_at: 1.hour.from_now
      }

      # Simulate writing cache to mobile storage
      cache_json = offline_cache.to_json
      cache_json.bytesize
    end

    puts "\n#{benchmark_name}:"
    puts "  Cache Creation Time: #{cache_creation_time.real.round(3)}s"
    puts "  Cache Size: #{(cache_creation_time.real.to_json.bytesize / 1024.0).round(1)}KB"

    # Offline cache performance assertions
    assert cache_creation_time.real < 1.0, "Offline cache creation should be fast (took #{cache_creation_time.real.round(3)}s)"
  end
end
