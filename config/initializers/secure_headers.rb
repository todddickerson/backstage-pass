# Secure Headers Configuration for all environments
SecureHeaders::Configuration.default do |config|
  # Basic security headers
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w[origin-when-cross-origin strict-origin-when-cross-origin]

  # CSP Configuration
  # TODO: Tighten CSP rules after testing in production (Issue #29)
  csp_rules = {
    default_src: %w['self'],
    script_src: %w['self' 'unsafe-inline' 'unsafe-eval' https://unpkg.com https://cdn.jsdelivr.net],
    style_src: %w['self' 'unsafe-inline' https://fonts.googleapis.com],
    img_src: %w['self' data: https: blob:],
    font_src: %w['self' data: https://fonts.gstatic.com],
    connect_src: %w['self' wss: https: wss://*.livekit.cloud https://*.stripe.com wss://*.getstream.io https://*.getstream.io],
    media_src: %w['self' blob: https:],
    object_src: %w['none'],
    form_action: %w['self' https://checkout.stripe.com],
    base_uri: %w['self'],
    frame_ancestors: %w['none'],
    frame_src: %w['self' https://js.stripe.com https://checkout.stripe.com],
    worker_src: %w['self' blob:],
    manifest_src: %w['self'],
    upgrade_insecure_requests: false
  }

  config.csp = if Rails.env.production?
    # Use report-only mode in production temporarily
    # SECURITY: Enable enforcement after testing (Issue #29)
    csp_rules.merge(report_only: true)
  else
    # Full CSP enforcement in dev/test
    csp_rules
  end
end

# API endpoints don't need CSP
SecureHeaders::Configuration.override(:api) do |config|
  config.csp = SecureHeaders::OPT_OUT
  config.x_frame_options = SecureHeaders::OPT_OUT
end
