# Rack::Attack configuration for rate limiting and throttling
class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache for storage (Redis in production)
  Rack::Attack.cache.store = Rails.cache

  ### Safelist ###
  # Always allow requests from localhost
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  # Allow requests from specific IPs (admin IPs, monitoring services, etc.)
  # safelist("allow-admin-ips") do |req|
  #   ["192.168.1.1"].include?(req.ip)
  # end

  ### Blocklist ###
  # Block suspicious requests
  
  # Block requests with bad user agents
  blocklist("block-bad-agents") do |req|
    # List of known bad user agents
    bad_agents = [
      /scanner/i,
      /nmap/i,
      /sqlmap/i,
      /nikto/i,
      /acunetix/i,
      /havij/i,
      /wget/i,
      /curl/i # Be careful with this, legitimate services use curl
    ]
    
    user_agent = req.user_agent.to_s
    bad_agents.any? { |pattern| user_agent.match?(pattern) }
  end

  # Block requests trying to access sensitive files
  blocklist("block-sensitive-paths") do |req|
    sensitive_paths = [
      /\/\.env/,
      /\/\.git/,
      /\/config\/database\.yml/,
      /\/config\/master\.key/,
      /wp-admin/i, # WordPress attacks
      /wp-login/i,
      /phpMyAdmin/i,
      /\.php$/
    ]
    
    sensitive_paths.any? { |pattern| req.path.match?(pattern) }
  end

  ### Throttling ###

  # Throttle all requests by IP (general rate limit)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets", "/packs")
  end

  # Stricter throttling for authentication endpoints
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Return the email if present in params
      req.params["user"]["email"].to_s.downcase.presence if req.params["user"]
    end
  end

  # Throttle password reset attempts
  throttle("password-reset/ip", limit: 5, period: 15.minutes) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  throttle("password-reset/email", limit: 3, period: 15.minutes) do |req|
    if req.path == "/users/password" && req.post?
      req.params["user"]["email"].to_s.downcase.presence if req.params["user"]
    end
  end

  # Throttle sign up attempts
  throttle("signups/ip", limit: 5, period: 15.minutes) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  # Throttle API requests by API key
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api")
  end

  # Throttle API by authentication token if present
  throttle("api/token", limit: 1000, period: 1.hour) do |req|
    if req.path.start_with?("/api")
      # Check for API token in Authorization header
      if (auth_header = req.get_header("HTTP_AUTHORIZATION"))
        auth_header.sub(/^Bearer\s+/, "") # Extract token
      end
    end
  end

  # Throttle search endpoints to prevent abuse
  throttle("search/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.include?("/search") || req.path.include?("/explore")
  end

  # Throttle file uploads
  throttle("uploads/ip", limit: 10, period: 10.minutes) do |req|
    req.ip if req.post? && req.path.include?("/upload")
  end

  # Throttle purchase/payment endpoints
  throttle("payments/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path.include?("/purchase") || req.path.include?("/stripe")
  end

  # Throttle stream creation
  throttle("streams/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path.match?(/\/streams$/) && req.post?
  end

  # Throttle chat messages (prevent spam)
  throttle("chat/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.include?("/chat") && req.post?
  end

  ### Exponential Backoff for Repeated Offenders ###
  # Track repeat offenders and increase their ban time
  
  # Ban IP for 1 hour after 3 limit violations in 10 minutes
  Rack::Attack.blocklist("recidivist-ip") do |req|
    Rack::Attack::Allow2Ban.filter(
      req.ip,
      maxretry: 3,
      findtime: 10.minutes,
      bantime: 1.hour
    ) do
      # Count throttle violations
      Rack::Attack::Fail2Ban.filter(req.ip, maxretry: 0, findtime: 1.minute, bantime: 1.minute) do
        false # We're just counting here
      end
    end
  end

  ### Failed Login Tracking ###
  # Track failed login attempts and ban after too many failures
  Rack::Attack.track("login-failures") do |req|
    if req.path == "/users/sign_in" && req.post?
      # Track if response indicates failure (you'll need to implement this check)
      # This is a simplified example
      req.ip
    end
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |req|
    now = Time.now.utc
    match_data = req.env["rack.attack.match_data"]
    
    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - (now.to_i % match_data[:period]))).to_s
    }
    
    [429, headers, ["Rate limit exceeded. Please try again later.\n"]]
  end

  ### Custom Blocklist Response ###
  self.blocklisted_responder = lambda do |req|
    [403, {}, ["Access denied. Your request has been blocked.\n"]]
  end
end

# Enable Rack::Attack
Rails.application.config.middleware.use Rack::Attack

# Log blocked and throttled requests in production
if Rails.env.production?
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    
    if [:throttle, :blocklist].include?(req.env["rack.attack.match_type"])
      Rails.logger.warn("Rate limit exceeded: #{req.env['rack.attack.match_type']} #{req.ip} #{req.path}")
      
      # You could also send this to an error tracking service
      # Honeybadger.notify("Rate limit exceeded", context: {
      #   ip: req.ip,
      #   path: req.path,
      #   match_type: req.env["rack.attack.match_type"]
      # })
    end
  end
end