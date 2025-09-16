SecureHeaders::Configuration.default do |config|
  # Prevent clickjacking
  config.x_frame_options = "DENY"
  
  # Prevent MIME type sniffing
  config.x_content_type_options = "nosniff"
  
  # Enable XSS protection in older browsers
  config.x_xss_protection = "1; mode=block"
  
  # Prevent IE from opening downloads in the browser
  config.x_download_options = "noopen"
  
  # Prevent Flash cross-domain policy issues
  config.x_permitted_cross_domain_policies = "none"
  
  # Control referrer information
  config.referrer_policy = %w[origin-when-cross-origin strict-origin-when-cross-origin]
  
  # Content Security Policy - This is crucial for XSS prevention
  config.csp = {
    # Fallback for any undefined source
    default_src: %w['self'],
    
    # JavaScript sources
    script_src: %w[
      'self'
      'unsafe-inline' # Required for Turbo and inline scripts
      https://unpkg.com # For Stimulus/Turbo from CDN
      https://cdn.jsdelivr.net # For libraries
    ],
    
    # Stylesheets
    style_src: %w[
      'self'
      'unsafe-inline' # Required for inline styles
      https://fonts.googleapis.com
    ],
    
    # Images
    img_src: %w[
      'self'
      data: # For inline images
      https: # Allow all HTTPS images (for user uploads, avatars, etc.)
      blob: # For blob URLs used by file uploads
    ],
    
    # Fonts
    font_src: %w[
      'self'
      data: # For inline fonts
      https://fonts.gstatic.com
    ],
    
    # AJAX, WebSocket, and EventSource connections
    connect_src: %w[
      'self'
      wss: # WebSocket connections for ActionCable
      https: # API calls
      wss://*.livekit.cloud # LiveKit WebRTC
      https://*.stripe.com # Stripe
      wss://*.getstream.io # GetStream chat
      https://*.getstream.io
    ],
    
    # Media (audio/video)
    media_src: %w[
      'self'
      blob: # For blob URLs
      https: # For CDN-hosted media
    ],
    
    # Object/embed tags (Flash, etc.) - typically none
    object_src: %w['none'],
    
    # Form submission destinations
    form_action: %w[
      'self'
      https://checkout.stripe.com # Stripe checkout
    ],
    
    # Restrict base tag
    base_uri: %w['self'],
    
    # Restrict framing to same origin
    frame_ancestors: %w['none'],
    
    # Child frames
    frame_src: %w[
      'self'
      https://js.stripe.com # Stripe Elements iframe
      https://checkout.stripe.com
    ],
    
    # Workers
    worker_src: %w['self' blob:],
    
    # Manifest
    manifest_src: %w['self'],
    
    # Upgrade insecure requests
    upgrade_insecure_requests: Rails.env.production?, # Only in production
    
    # Report violations (optional - requires endpoint setup)
    # report_uri: %w[/csp-violation-report-endpoint]
  }
  
  # Note: Permissions Policy is not directly supported in secure_headers 6.x
  # We'll set it via response headers in the application controller instead
  
  # Note: Additional headers already configured above
  
  # HSTS (HTTP Strict Transport Security)
  # Only enable in production with proper SSL setup
  if Rails.env.production?
    config.hsts = {
      max_age: 31_536_000, # 1 year
      include_subdomains: true,
      preload: true
    }
  end
end

# Configure for different environments if needed
if Rails.env.development?
  # More relaxed CSP for development
  SecureHeaders::Configuration.override(:development) do |config|
    config.csp[:script_src] << "'unsafe-eval'" # For better debugging
  end
end

# Special configuration for API endpoints (no CSP needed)
SecureHeaders::Configuration.override(:api) do |config|
  config.csp = SecureHeaders::OPT_OUT
  config.x_frame_options = SecureHeaders::OPT_OUT
end