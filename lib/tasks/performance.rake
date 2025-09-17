# Performance analysis and optimization tasks for Backstage Pass

namespace :performance do
  desc "Analyze database performance and suggest optimizations"
  task analyze: :environment do
    puts "🚀 Backstage Pass Performance Analysis"
    puts "======================================"

    # Check database indexes
    puts "\n📊 Database Indexes Analysis:"

    # Check for missing indexes on foreign keys
    missing_indexes = []
    ActiveRecord::Base.connection.tables.each do |table|
      columns = ActiveRecord::Base.connection.columns(table)
      foreign_keys = columns.select { |col| col.name.end_with?("_id") }

      foreign_keys.each do |fk|
        indexes = ActiveRecord::Base.connection.indexes(table)
        has_index = indexes.any? { |idx| idx.columns.include?(fk.name) || idx.columns.first == fk.name }

        unless has_index
          missing_indexes << "#{table}.#{fk.name}"
        end
      end
    end

    if missing_indexes.any?
      puts "⚠️  Missing indexes on foreign keys:"
      missing_indexes.each { |idx| puts "   - #{idx}" }
    else
      puts "✅ All foreign keys are properly indexed"
    end

    # Check table sizes
    puts "\n📈 Table Sizes:"
    %w[spaces experiences streams access_grants access_passes users teams memberships].each do |table|
      if ActiveRecord::Base.connection.table_exists?(table)
        count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table}")
        puts "   #{table}: #{count} records"
      end
    end

    # Check counter cache accuracy
    puts "\n🔢 Counter Cache Validation:"

    # Validate spaces counter caches
    Space.find_each do |space|
      actual_experiences = space.experiences.count
      cached_experiences = space.experiences_count

      if actual_experiences != cached_experiences
        puts "⚠️  Space #{space.id}: experiences_count mismatch (actual: #{actual_experiences}, cached: #{cached_experiences})"
      end

      actual_access_passes = space.access_passes.count
      cached_access_passes = space.access_passes_count

      if actual_access_passes != cached_access_passes
        puts "⚠️  Space #{space.id}: access_passes_count mismatch (actual: #{actual_access_passes}, cached: #{cached_access_passes})"
      end
    end

    puts "✅ Counter cache validation complete"

    # Memory usage
    puts "\n💾 Current Memory Usage:"
    if /darwin/.match?(RbConfig::CONFIG["host_os"])  # macOS
      memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
      puts "   RSS Memory: #{memory_mb}MB"
    end

    # Cache statistics (if Redis is available)
    puts "\n🗄️  Cache Status:"
    begin
      if Rails.cache.respond_to?(:redis)
        info = Rails.cache.redis.info
        puts "   Redis Memory: #{info["used_memory_human"]}"
        puts "   Redis Keys: #{Rails.cache.redis.dbsize}"
      else
        puts "   Cache Store: #{Rails.cache.class.name}"
      end
    rescue => e
      puts "   Cache Status: Not available (#{e.message})"
    end

    puts "\n✨ Performance Analysis Complete!"
  end

  desc "Reset all counter caches"
  task reset_counters: :environment do
    puts "🔄 Resetting Counter Caches..."

    # Reset spaces counters
    Space.find_each do |space|
      Space.reset_counters(space.id, :experiences, :access_passes)
      print "."
    end

    # Reset experiences counters
    Experience.find_each do |experience|
      Experience.reset_counters(experience.id, :streams)
      print "."
    end

    # Reset teams counters
    Team.find_each do |team|
      Team.reset_counters(team.id, :spaces, :memberships)
      print "."
    end

    # Reset access passes counters
    AccessPass.find_each do |access_pass|
      AccessPass.reset_counters(access_pass.id, :access_grants)
      print "."
    end

    puts "\n✅ Counter caches reset complete!"
  end

  desc "Clear all application caches"
  task clear_cache: :environment do
    puts "🧹 Clearing Application Caches..."

    Rails.cache.clear
    puts "✅ Application cache cleared!"

    # Clear specific cache patterns
    if Rails.cache.respond_to?(:delete_matched)
      Rails.cache.delete_matched("space_*/total_*")
      Rails.cache.delete_matched("space_*/user_*/role")
      puts "✅ Space-specific caches cleared!"
    end
  end

  desc "Performance benchmark - simulate typical user actions"
  task benchmark: :environment do
    require "benchmark"

    puts "⏱️  Performance Benchmark"
    puts "========================"

    # Ensure we have test data
    unless Space.exists?
      puts "❌ No spaces found. Create some test data first."
      exit 1
    end

    space = Space.published.first
    unless space
      puts "❌ No published spaces found. Create some test data first."
      exit 1
    end

    puts "🎯 Testing with Space: #{space.name}"

    # Benchmark key operations
    puts "\n📊 Benchmarking key operations (10 iterations each):"

    Benchmark.bm(25) do |x|
      x.report("Space.published.all") do
        10.times { Space.published.includes(:team, :experiences).to_a }
      end

      x.report("Space.find with includes") do
        10.times do
          Space.includes(:team, {experiences: [:streams]}, :access_passes).find(space.id)
        end
      end

      x.report("space.total_members") do
        10.times { space.total_members }
      end

      x.report("space.experiences") do
        10.times { space.experiences.to_a }
      end

      if space.experiences.any?
        experience = space.experiences.first
        x.report("experience.streams") do
          10.times { experience.streams.to_a }
        end
      end
    end

    puts "\n✅ Benchmark complete!"
    puts "💡 Tip: Run this periodically to track performance improvements"
  end

  desc "Generate performance report"
  task report: :environment do
    puts "📋 Backstage Pass Performance Report"
    puts "===================================="
    puts "Generated: #{Time.current}"
    puts

    # Run sub-tasks
    Rake::Task["performance:analyze"].execute

    puts "\n📝 Recommendations:"
    puts "==================="
    puts "1. Monitor slow queries in logs (>100ms in development, >50ms in production)"
    puts "2. Use 'rails performance:benchmark' to track performance over time"
    puts "3. Monitor memory usage in production with APM tools"
    puts "4. Consider adding more caching for frequently accessed data"
    puts "5. Review database indexes quarterly as data grows"
    puts
    puts "🔗 Useful commands:"
    puts "   rails performance:analyze    - Analyze current performance"
    puts "   rails performance:benchmark  - Run performance benchmarks"
    puts "   rails performance:clear_cache - Clear application caches"
    puts "   rails performance:reset_counters - Reset counter caches"
  end
end
