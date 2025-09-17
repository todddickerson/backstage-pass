require "test_helper"
require "benchmark"

class SimplifiedPerformanceTest < ActiveSupport::TestCase
  setup do
    @creator = create(:onboarded_user, first_name: "Creator", last_name: "Perf")
    @space = @creator.current_team.primary_space
  end

  test "creator content creation performance baseline" do
    benchmark_name = "Creator Content Creation Performance"

    time = Benchmark.measure do
      # Create multiple experiences (typical creator workflow)
      10.times do |i|
        experience = @space.experiences.create!(
          name: "Performance Experience #{i}",
          description: "Testing content creation performance",
          experience_type: "live_stream",
          price_cents: 2000 + (i * 500)
        )

        # Create streams for each experience
        3.times do |j|
          stream = experience.streams.create!(
            title: "Performance Stream #{i}-#{j}",
            description: "Testing stream creation performance",
            scheduled_at: (j + 1).hours.from_now,
            status: "scheduled"
          )

          # Create chat room for each stream
          stream.streaming_chat_rooms.create!(
            channel_id: "perf_#{i}_#{j}_#{SecureRandom.hex(4)}"
          )
        end

        # Create access passes
        2.times do |k|
          @space.access_passes.create!(
            name: "Performance Pass #{i}-#{k}",
            description: "Testing access pass creation",
            pricing_type: ["one_time", "monthly"][k % 2],
            price_cents: 1000 + (k * 1000),
            published: true
          )
        end
      end
    end

    puts "\n#{benchmark_name}:"
    puts "  Time: #{time.real.round(3)}s"
    puts "  CPU: #{time.total.round(3)}s"
    puts "  Objects Created: 10 experiences, 30 streams, 30 chat rooms, 20 access passes"

    # Performance assertions
    assert time.real < 3.0, "Content creation should complete quickly (took #{time.real.round(3)}s)"

    # Verify data was created correctly
    assert_equal 10, @space.experiences.count # 10 new experiences created
    assert_equal 30, @space.experiences.joins(:streams).count
    assert_equal 20, @space.access_passes.count
  end

  test "query performance with realistic data volumes" do
    benchmark_name = "Query Performance with Realistic Data"

    # Set up realistic data structure
    5.times do |space_i|
      space = @creator.current_team.spaces.create!(
        name: "Query Test Space #{space_i}",
        description: "Testing query performance"
      )

      10.times do |exp_i|
        experience = space.experiences.create!(
          name: "Query Experience #{space_i}-#{exp_i}",
          description: "Query performance testing",
          experience_type: "live_stream",
          price_cents: 1999
        )

        5.times do |stream_i|
          stream = experience.streams.create!(
            title: "Query Stream #{space_i}-#{exp_i}-#{stream_i}",
            description: "Query test stream",
            scheduled_at: stream_i.hours.from_now,
            status: ["scheduled", "live", "ended"][stream_i % 3]
          )

          stream.streaming_chat_rooms.create!(
            channel_id: "query_#{space_i}_#{exp_i}_#{stream_i}"
          )
        end
      end
    end

    # Test various query patterns
    query_time = Benchmark.measure do
      # 1. Creator's total content
      @creator.current_team.spaces
        .joins(:experiences)
        .count

      # 2. Active streams across all spaces
      @creator.current_team.spaces
        .joins(experiences: :streams)
        .where("streams.status = ?", "live")
        .count

      # 3. Chat rooms for live streams
      @creator.current_team.spaces
        .joins(experiences: {streams: :streaming_chat_rooms})
        .where("streams.status = ?", "live")
        .count

      # 4. Pricing analysis
      @creator.current_team.spaces
        .joins(:experiences)
        .group("experiences.experience_type")
        .average("experiences.price_cents")

      # 5. Content statistics
      @creator.current_team.spaces
        .joins(:experiences)
        .group("spaces.name")
        .count
    end

    puts "\n#{benchmark_name}:"
    puts "  Query Time: #{query_time.real.round(3)}s"
    puts "  CPU: #{query_time.total.round(3)}s"

    # Performance assertions
    assert query_time.real < 1.0, "Complex queries should complete quickly (took #{query_time.real.round(3)}s)"
  end

  test "streaming infrastructure performance" do
    benchmark_name = "Streaming Infrastructure Performance"

    experience = @space.experiences.create!(
      name: "Streaming Performance Test",
      description: "Testing streaming infrastructure",
      experience_type: "live_stream",
      price_cents: 2999
    )

    streaming_time = Benchmark.measure do
      # Simulate creating multiple concurrent streams
      streams = 20.times.map do |i|
        stream = experience.streams.create!(
          title: "Concurrent Stream #{i}",
          description: "Testing concurrent stream performance",
          scheduled_at: Time.current + i.minutes,
          status: "scheduled"
        )

        # Each stream gets a chat room
        chat_room = stream.streaming_chat_rooms.create!(
          channel_id: "concurrent_#{i}_#{SecureRandom.hex(4)}"
        )

        # Simulate stream lifecycle
        stream.update!(status: "live") if i.even?

        {stream: stream, chat_room: chat_room}
      end

      # Test stream operations
      streams.each do |stream_data|
        stream = stream_data[:stream]
        chat_room = stream_data[:chat_room]

        # Mock operations that would happen during streaming
        stream.room_name
        stream.can_broadcast?(@creator)
        chat_room.can_access?(@creator)
      end
    end

    puts "\n#{benchmark_name}:"
    puts "  Time: #{streaming_time.real.round(3)}s"
    puts "  Streams Created: 20"
    puts "  Per Stream: #{(streaming_time.real / 20 * 1000).round(1)}ms"

    # Performance assertions
    assert streaming_time.real < 2.0, "Streaming infrastructure should scale well (took #{streaming_time.real.round(3)}s)"
    assert (streaming_time.real / 20) < 0.1, "Each stream should be fast to create (took #{(streaming_time.real / 20 * 1000).round(1)}ms)"
  end

  test "database query optimization" do
    benchmark_name = "Database Query Optimization"

    # Create test data
    experience = @space.experiences.create!(
      name: "DB Optimization Test",
      description: "Testing database query optimization",
      experience_type: "live_stream",
      price_cents: 1999
    )

    streams = 5.times.map do |i|
      stream = experience.streams.create!(
        title: "DB Test Stream #{i}",
        description: "Database query testing",
        scheduled_at: i.hours.from_now,
        status: ["scheduled", "live", "ended"][i % 3]
      )

      stream.streaming_chat_rooms.create!(
        channel_id: "db_test_#{i}"
      )

      stream
    end

    # Test efficient vs inefficient query patterns
    efficient_time = Benchmark.measure do
      # Efficient query with includes
      streams_with_data = @space.experiences
        .includes(streams: :streaming_chat_rooms)
        .flat_map(&:streams)

      # Access associated data (should not trigger N+1)
      streams_with_data.each do |stream|
        stream.streaming_chat_rooms.count
        stream.experience.name
      end
    end

    puts "\n#{benchmark_name}:"
    puts "  Efficient Query Time: #{efficient_time.real.round(3)}s"
    puts "  Streams Processed: #{streams.count}"

    # Performance assertions
    assert efficient_time.real < 0.5, "Efficient queries should be very fast (took #{efficient_time.real.round(3)}s)"
  end

  test "mobile api response time simulation" do
    benchmark_name = "Mobile API Response Time Simulation"

    # Create realistic data for mobile API
    3.times do |i|
      experience = @space.experiences.create!(
        name: "Mobile API Experience #{i}",
        description: "Testing mobile API performance",
        experience_type: "live_stream",
        price_cents: 1999 + (i * 500)
      )

      2.times do |j|
        stream = experience.streams.create!(
          title: "Mobile Stream #{i}-#{j}",
          description: "Mobile API test stream",
          scheduled_at: j.hours.from_now,
          status: ["scheduled", "live"][j % 2]
        )

        stream.streaming_chat_rooms.create!(
          channel_id: "mobile_#{i}_#{j}"
        )
      end
    end

    # Simulate common mobile API calls
    api_times = {}

    # 1. User profile and spaces
    api_times[:user_profile] = Benchmark.measure do
      {
        id: @creator.id,
        name: @creator.name,
        teams: @creator.teams.includes(:spaces).map do |team|
          {
            id: team.id,
            name: team.name,
            spaces_count: team.spaces.count
          }
        end
      }
    end

    # 2. Space content listing
    api_times[:space_content] = Benchmark.measure do
      {
        id: @space.id,
        name: @space.name,
        experiences: @space.experiences.includes(:streams).map do |exp|
          {
            id: exp.id,
            name: exp.name,
            streams_count: exp.streams.count,
            live_streams_count: exp.streams.where(status: "live").count
          }
        end
      }
    end

    # 3. Live stream discovery
    api_times[:live_streams] = Benchmark.measure do
      @creator.current_team.spaces
        .joins(experiences: :streams)
        .where("streams.status = ?", "live")
        .includes(experiences: {streams: :streaming_chat_rooms})
        .map do |space|
          space.experiences.flat_map(&:streams).select { |s| s.status == "live" }
        end.flatten
    end

    puts "\n#{benchmark_name}:"
    api_times.each do |endpoint, time|
      puts "  #{endpoint}: #{(time.real * 1000).round(1)}ms"

      # Mobile performance targets (should be under 200ms for good UX)
      assert time.real < 0.2, "#{endpoint} should respond quickly for mobile (took #{(time.real * 1000).round(1)}ms)"
    end
  end

  test "memory usage estimation" do
    benchmark_name = "Memory Usage Estimation"

    initial_memory = get_memory_usage

    creation_time = Benchmark.measure do
      # Create substantial amount of data
      5.times do |space_i|
        space = @creator.current_team.spaces.create!(
          name: "Memory Test Space #{space_i}",
          description: "Testing memory usage"
        )

        10.times do |exp_i|
          experience = space.experiences.create!(
            name: "Memory Experience #{space_i}-#{exp_i}",
            description: "Memory testing experience",
            experience_type: "live_stream",
            price_cents: 2000
          )

          3.times do |stream_i|
            stream = experience.streams.create!(
              title: "Memory Stream #{space_i}-#{exp_i}-#{stream_i}",
              description: "Memory test stream",
              scheduled_at: stream_i.hours.from_now,
              status: "scheduled"
            )

            stream.streaming_chat_rooms.create!(
              channel_id: "memory_#{space_i}_#{exp_i}_#{stream_i}"
            )
          end
        end
      end
    end

    final_memory = get_memory_usage
    memory_increase = final_memory - initial_memory

    puts "\n#{benchmark_name}:"
    puts "  Creation Time: #{creation_time.real.round(3)}s"
    puts "  Initial Memory: #{initial_memory.round(1)}MB"
    puts "  Final Memory: #{final_memory.round(1)}MB"
    puts "  Memory Increase: #{memory_increase.round(1)}MB"
    puts "  Objects Created: 5 spaces, 50 experiences, 150 streams"

    # Memory assertions
    assert memory_increase < 50, "Memory increase should be reasonable (increased #{memory_increase.round(1)}MB)"
    assert creation_time.real < 5.0, "Object creation should be efficient (took #{creation_time.real.round(3)}s)"
  end

  private

  def get_memory_usage
    # Get current process memory usage in MB
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue
    0 # Fallback if ps command fails
  end
end
