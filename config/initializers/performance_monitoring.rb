# Performance Monitoring Configuration for Backstage Pass
# Tracks database queries, slow requests, and memory usage

# Database query monitoring
if Rails.env.development? || Rails.env.production?
  require "active_support/notifications"

  # Track slow database queries
  ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
    duration = (finish - start) * 1000 # Convert to milliseconds

    # Log slow queries (> 100ms in development, > 50ms in production)
    threshold = Rails.env.production? ? 50 : 100

    if duration > threshold
      Rails.logger.warn "[SLOW QUERY] #{duration.round(2)}ms: #{payload[:sql]}"

      # In development, also log the source location
      if Rails.env.development?
        caller_info = caller.find { |line| !line.include?("active_record") }
        Rails.logger.warn "[SLOW QUERY SOURCE] #{caller_info}" if caller_info
      end
    end
  end

  # Track N+1 queries in development
  if Rails.env.development?
    query_count = 0
    query_tracker = {}

    ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      query_count += 1
      sql = payload[:sql]

      # Track similar queries that might indicate N+1
      normalized_sql = sql.gsub(/\d+/, "?").gsub(/"[^"]*"/, "?")
      query_tracker[normalized_sql] ||= 0
      query_tracker[normalized_sql] += 1

      # Warn about potential N+1 queries (same query pattern > 5 times)
      if query_tracker[normalized_sql] == 6
        Rails.logger.warn "[POTENTIAL N+1] Query executed 6+ times: #{normalized_sql}"
      end
    end

    # Reset query tracker for each request
    Rails.application.config.middleware.use(Class.new do
      def initialize(app)
        @app = app
      end

      def call(env)
        query_tracker.clear if defined?(query_tracker)
        @app.call(env)
      end
    end)
  end
end

# Request performance monitoring
if Rails.env.production? || Rails.env.development?
  ActiveSupport::Notifications.subscribe("process_action.action_controller") do |name, start, finish, id, payload|
    duration = (finish - start) * 1000

    # Log slow requests (> 500ms in production, > 1000ms in development)
    threshold = Rails.env.production? ? 500 : 1000

    if duration > threshold
      controller = payload[:controller]
      action = payload[:action]
      db_time = payload[:db_runtime]&.round(2)
      view_time = payload[:view_runtime]&.round(2)

      Rails.logger.warn [
        "[SLOW REQUEST] #{duration.round(2)}ms",
        "#{controller}##{action}",
        "DB: #{db_time}ms",
        "View: #{view_time}ms"
      ].compact.join(" | ")
    end
  end
end

# Memory usage monitoring (production only)
if Rails.env.production?
  require "objspace"

  # Monitor memory usage every 100 requests
  Rails.application.config.middleware.use(Class.new do
    def initialize(app)
      @app = app
      @request_count = 0
    end

    def call(env)
      @request_count += 1

      result = @app.call(env)

      if @request_count % 100 == 0
        memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
        object_count = ObjectSpace.count_objects[:TOTAL] - ObjectSpace.count_objects[:FREE]

        Rails.logger.info "[MEMORY] #{memory_mb}MB RSS, #{object_count} objects after #{@request_count} requests"

        # Alert on high memory usage (> 512MB)
        if memory_mb > 512
          Rails.logger.warn "[HIGH MEMORY] Process using #{memory_mb}MB"
        end
      end

      result
    end
  end)
end

# Cache performance monitoring
if Rails.env.production? || Rails.env.development?
  cache_hits = 0
  cache_misses = 0

  ActiveSupport::Notifications.subscribe("cache_read.active_support") do |name, start, finish, id, payload|
    if payload[:hit]
      cache_hits += 1
    else
      cache_misses += 1
    end

    # Log cache statistics every 100 cache operations
    total = cache_hits + cache_misses
    if total > 0 && total % 100 == 0
      hit_rate = (cache_hits.to_f / total * 100).round(1)
      Rails.logger.info "[CACHE] Hit rate: #{hit_rate}% (#{cache_hits}/#{total})"

      # Alert on low cache hit rate (< 70%)
      if hit_rate < 70
        Rails.logger.warn "[LOW CACHE HIT RATE] #{hit_rate}% - consider cache optimization"
      end
    end
  end
end

# Development-only query analysis
if Rails.env.development?
  # Add middleware to show query count for each request
  Rails.application.config.middleware.use(Class.new do
    def initialize(app)
      @app = app
    end

    def call(env)
      query_count = 0

      # Count queries during request
      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
        query_count += 1 unless payload[:name] == "SCHEMA"
      end

      result = @app.call(env)

      ActiveSupport::Notifications.unsubscribe(subscription)

      # Log query count for requests with many queries
      if query_count > 10
        path = env["PATH_INFO"]
        method = env["REQUEST_METHOD"]
        Rails.logger.info "[QUERY COUNT] #{query_count} queries for #{method} #{path}"
      end

      result
    end
  end)
end

Rails.logger.info "[PERFORMANCE MONITORING] Initialized for #{Rails.env} environment"
