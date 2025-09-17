require "test_helper"
require "benchmark"

class CreatorEconomyPerformanceTest < ActiveSupport::TestCase
  setup do
    @creator = create(:onboarded_user, first_name: "Creator", last_name: "Performance")
    @space = @creator.current_team.primary_space

    # Create baseline data for more realistic testing
    @customers = 10.times.map do |i|
      create(:onboarded_user, first_name: "Customer#{i}", last_name: "Performance")
    end
  end

  test "creator onboarding workflow performance baseline" do
    benchmark_name = "Creator Onboarding Workflow"

    time = Benchmark.measure do
      # Simulate complete creator onboarding
      new_creator = create(:user, first_name: "New", last_name: "Creator")

      # Create team and space (typical onboarding)
      team = new_creator.teams.create!(name: "Performance Test Team")
      space = team.spaces.create!(
        name: "Creator Performance Space",
        description: "Testing creator setup performance"
      )

      # Create initial experience
      space.experiences.create!(
        name: "Performance Test Experience",
        description: "Testing experience creation performance",
        experience_type: "live_stream",
        price_cents: 2999
      )

      # Create access pass
      space.access_passes.create!(
        name: "Performance Access Pass",
        description: "Testing access pass creation",
        pricing_type: "one_time",
        price_cents: 1999,
        published: true
      )
    end

    puts "\n#{benchmark_name}:"
    puts "  Time: #{time.real.round(3)}s"
    puts "  CPU: #{time.total.round(3)}s"

    # Performance assertions
    assert time.real < 1.0, "Creator onboarding should complete in under 1 second (took #{time.real.round(3)}s)"
  end

  test "bulk access grant creation performance" do
    benchmark_name = "Bulk Access Grant Creation (100 customers)"

    # Create test access pass
    access_pass = @space.access_passes.create!(
      name: "Bulk Test Access Pass",
      description: "Testing bulk access grant performance",
      pricing_type: "one_time",
      price_cents: 999,
      published: true
    )

    # Create 100 test customers
    timestamp = Time.current.to_i
    customers = 100.times.map do |i|
      create(:onboarded_user,
        first_name: "BulkCustomer#{i}",
        last_name: "Performance",
        email: "bulk_customer_#{timestamp}_#{i}_#{SecureRandom.hex(6)}@example.com")
    end

    time = Benchmark.measure do
      # Simulate bulk purchase scenario (e.g., flash sale)
      customers.each do |customer|
        @creator.current_team.access_grants.create!(
          access_pass: access_pass,
          user: customer,
          status: "active",
          purchasable: access_pass.space
        )
      end
    end

    puts "\n#{benchmark_name}:"
    puts "  Time: #{time.real.round(3)}s"
    puts "  CPU: #{time.total.round(3)}s"
    puts "  Per Grant: #{(time.real / 100).round(5)}s"

    # Performance assertions
    assert time.real < 5.0, "100 access grants should be created in under 5 seconds (took #{time.real.round(3)}s)"
    assert (time.real / 100) < 0.05, "Each access grant should take less than 50ms (took #{((time.real / 100) * 1000).round(1)}ms)"
  end

  test "streaming room creation and management performance" do
    benchmark_name = "Streaming Infrastructure Performance"

    experience = @space.experiences.create!(
      name: "Performance Stream Experience",
      description: "Testing streaming performance",
      experience_type: "live_stream",
      price_cents: 4999
    )

    time = Benchmark.measure do
      # Create 10 concurrent streams (realistic for a popular creator)
      streams = 10.times.map do |i|
        experience.streams.create!(
          title: "Performance Stream #{i}",
          description: "Testing stream creation performance",
          scheduled_at: (i + 1).hours.from_now,
          status: "scheduled"
        )
      end

      # Create chat rooms for each stream
      streams.each do |stream|
        stream.streaming_chat_rooms.create!(
          channel_id: "perf_stream_#{stream.id}_chat"
        )
      end

      # Simulate stream lifecycle changes
      streams.each_with_index do |stream, i|
        stream.update!(status: "live")
        stream.update!(status: "ended") if i.even? # End half the streams
      end
    end

    puts "\n#{benchmark_name}:"
    puts "  Time: #{time.real.round(3)}s"
    puts "  CPU: #{time.total.round(3)}s"

    # Performance assertions
    assert time.real < 3.0, "Streaming infrastructure setup should complete in under 3 seconds (took #{time.real.round(3)}s)"
  end

  test "access control query performance with large user base" do
    benchmark_name = "Access Control Performance (1000 users)"

    # Create access pass
    access_pass = @space.access_passes.create!(
      name: "Large Scale Access Pass",
      description: "Testing access control at scale",
      pricing_type: "one_time",
      price_cents: 1999,
      published: true
    )

    # Create experience
    experience = @space.experiences.create!(
      name: "Scalability Test Experience",
      description: "Testing access control performance",
      experience_type: "live_stream",
      price_cents: 2999
    )

    # Create large user base with mixed access
    users_with_access = 500.times.map do |i|
      user = create(:onboarded_user,
        first_name: "AccessUser#{i}",
        last_name: "Performance",
        email: "access_user_#{i}_#{SecureRandom.hex(4)}@example.com")

      # Grant access to these users
      @creator.current_team.access_grants.create!(
        access_pass: access_pass,
        user: user,
        status: "active",
        purchasable: experience
      )
      user
    end

    users_without_access = 500.times.map do |i|
      create(:onboarded_user,
        first_name: "NoAccessUser#{i}",
        last_name: "Performance",
        email: "no_access_user_#{i}_#{SecureRandom.hex(4)}@example.com")
    end

    all_users = users_with_access + users_without_access

    # Test access control query performance
    time = Benchmark.measure do
      all_users.each do |user|
        # This simulates the access check that happens on every stream view
        user.access_grants.active.where(
          purchasable: [experience, experience.space]
        ).exists?
      end
    end

    puts "\n#{benchmark_name}:"
    puts "  Time: #{time.real.round(3)}s"
    puts "  CPU: #{time.total.round(3)}s"
    puts "  Per Query: #{(time.real / 1000).round(5)}s"

    # Performance assertions
    assert time.real < 10.0, "1000 access control queries should complete in under 10 seconds (took #{time.real.round(3)}s)"
    assert (time.real / 1000) < 0.01, "Each access query should take less than 10ms (took #{((time.real / 1000) * 1000).round(1)}ms)"
  end

  test "complex query performance with joins and associations" do
    benchmark_name = "Complex Creator Economy Queries"

    # Set up complex data structure
    3.times do |space_i|
      space = @creator.current_team.spaces.create!(
        name: "Performance Space #{space_i}",
        description: "Testing complex query performance"
      )

      5.times do |exp_i|
        experience = space.experiences.create!(
          name: "Experience #{space_i}-#{exp_i}",
          description: "Complex query test experience",
          experience_type: "live_stream",
          price_cents: 1999 + (exp_i * 500)
        )

        # Create streams
        3.times do |stream_i|
          stream = experience.streams.create!(
            title: "Stream #{space_i}-#{exp_i}-#{stream_i}",
            description: "Performance test stream",
            scheduled_at: stream_i.hours.from_now,
            status: ["scheduled", "live", "ended"].sample
          )

          # Create chat rooms
          stream.streaming_chat_rooms.create!(
            channel_id: "complex_#{space_i}_#{exp_i}_#{stream_i}"
          )
        end

        # Create access passes
        2.times do |pass_i|
          space.access_passes.create!(
            name: "Access Pass #{space_i}-#{exp_i}-#{pass_i}",
            description: "Complex query test pass",
            pricing_type: ["one_time", "monthly"].sample,
            price_cents: 999 + (pass_i * 1000),
            published: true
          )
        end
      end
    end

    # Complex queries that would happen in real application
    time = Benchmark.measure do
      # 1. Get all creator's revenue data
      @creator.current_team
        .access_grants
        .active
        .joins(:access_pass)
        .sum("access_passes.price_cents")

      # 2. Get streaming analytics
      @creator.current_team.spaces
        .joins(experiences: :streams)
        .group("streams.status")
        .count

      # 3. Get most popular experiences
      @creator.current_team.spaces
        .joins(experiences: {access_grants: :user})
        .group("experiences.name")
        .count
        .sort_by { |_, count| -count }
        .first(5)

      # 4. Get chat room usage
      @creator.current_team.spaces
        .joins(experiences: {streams: :streaming_chat_rooms})
        .where("streams.status = ?", "live")
        .count

      # 5. Complex access control query (avoid polymorphic eager loading)
      @creator.current_team
        .access_grants
        .joins(:user, :access_pass)
        .group("users.email", "access_passes.name")
        .count
    end

    puts "\n#{benchmark_name}:"
    puts "  Time: #{time.real.round(3)}s"
    puts "  CPU: #{time.total.round(3)}s"

    # Performance assertions
    assert time.real < 5.0, "Complex analytics queries should complete in under 5 seconds (took #{time.real.round(3)}s)"
  end

  test "memory usage during peak activity simulation" do
    benchmark_name = "Memory Usage - Peak Activity"

    initial_memory = get_memory_usage

    # Simulate peak activity: many users, streams, and transactions
    peak_activity_time = Benchmark.measure do
      # Create multiple concurrent activities

      # 1. Multiple live streams
      10.times do |i|
        experience = @space.experiences.create!(
          name: "Peak Stream Experience #{i}",
          description: "Simulating peak load",
          experience_type: "live_stream",
          price_cents: 2999
        )

        stream = experience.streams.create!(
          title: "Peak Load Stream #{i}",
          description: "Testing memory usage under load",
          scheduled_at: Time.current,
          status: "live"
        )

        stream.streaming_chat_rooms.create!(
          channel_id: "peak_load_#{i}"
        )
      end

      # 2. Burst of access grants (flash sale scenario)
      access_pass = @space.access_passes.create!(
        name: "Flash Sale Access",
        description: "Peak load testing",
        pricing_type: "one_time",
        price_cents: 999,
        published: true
      )

      50.times do |i|
        customer = create(:onboarded_user,
          first_name: "Peak#{i}",
          last_name: "Customer",
          email: "peak_customer_#{i}_#{SecureRandom.hex(4)}@example.com")

        @creator.current_team.access_grants.create!(
          access_pass: access_pass,
          user: customer,
          status: "active",
          purchasable: @space
        )
      end
    end

    final_memory = get_memory_usage
    memory_increase = final_memory - initial_memory

    puts "\n#{benchmark_name}:"
    puts "  Time: #{peak_activity_time.real.round(3)}s"
    puts "  Initial Memory: #{initial_memory}MB"
    puts "  Final Memory: #{final_memory}MB"
    puts "  Memory Increase: #{memory_increase}MB"

    # Memory assertions
    assert memory_increase < 100, "Memory increase should be under 100MB during peak activity (increased #{memory_increase}MB)"
    assert final_memory < 500, "Total memory usage should stay under 500MB (used #{final_memory}MB)"
  end

  test "database query efficiency and N+1 prevention" do
    benchmark_name = "Query Efficiency - N+1 Prevention"

    # Set up data that commonly causes N+1 queries
    experience = @space.experiences.create!(
      name: "N+1 Test Experience",
      description: "Testing query efficiency",
      experience_type: "live_stream",
      price_cents: 2999
    )

    access_pass = @space.access_passes.create!(
      name: "N+1 Test Access",
      description: "Testing query efficiency",
      pricing_type: "one_time",
      price_cents: 1999,
      published: true
    )

    # Create 20 users with access grants
    20.times.map do |i|
      user = create(:onboarded_user,
        first_name: "QueryUser#{i}",
        last_name: "Test",
        email: "query_user_#{i}_#{SecureRandom.hex(4)}@example.com")

      @creator.current_team.access_grants.create!(
        access_pass: access_pass,
        user: user,
        status: "active",
        purchasable: experience
      )

      user
    end

    # Test efficient query patterns
    query_count = 0
    ActiveRecord::Base.logger

    query_time = Benchmark.measure do
      # Enable query counting
      ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
        query_count += 1
      end

      # This should be an efficient query with proper includes (avoid polymorphic)
      grants_with_associations = @creator.current_team
        .access_grants
        .includes(:user, :access_pass)
        .active
        .limit(20)

      # Access the associations (this is where N+1 would occur)
      grants_with_associations.each do |grant|
        grant.user.name
        grant.access_pass.name
        # Skip polymorphic association access for now
      end
    end

    puts "\n#{benchmark_name}:"
    puts "  Time: #{query_time.real.round(3)}s"
    puts "  Query Count: #{query_count}"
    puts "  Queries per Record: #{(query_count.to_f / 20).round(2)}"

    # Query efficiency assertions
    assert query_count < 10, "Should use efficient queries, not N+1 (used #{query_count} queries for 20 records)"
    assert query_time.real < 0.5, "Efficient queries should complete quickly (took #{query_time.real.round(3)}s)"
  end

  private

  def get_memory_usage
    # Get current process memory usage in MB
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue
    0 # Fallback if ps command fails
  end
end
