# Security headers and protections for controllers
module SecurityHeaders
  extend ActiveSupport::Concern

  included do
    # Ensure CSRF protection is enabled
    protect_from_forgery with: :exception

    # Add security callbacks
    before_action :set_security_headers
    before_action :validate_request_format
    before_action :sanitize_params

    # Rescue from common security exceptions
    rescue_from ActionController::InvalidAuthenticityToken do |exception|
      Rails.logger.warn "CSRF token validation failed: #{exception.message}"
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Security validation failed. Please try again." }
        format.json { render json: {error: "Invalid security token"}, status: :unprocessable_entity }
      end
    end

    rescue_from ActionController::ParameterMissing do |exception|
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "Required parameters missing" }
        format.json { render json: {error: "Required parameters missing: #{exception.param}"}, status: :bad_request }
      end
    end
  end

  private

  def set_security_headers
    # Additional runtime security headers
    response.headers["X-Request-Id"] = request.request_id

    # Prevent caching of sensitive data
    if user_signed_in?
      response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate, private"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "0"
    end
  end

  def validate_request_format
    # Prevent XXE attacks by rejecting XML requests
    if request.content_type&.include?("xml")
      render plain: "XML format not supported", status: :unsupported_media_type
      false
    end
  end

  def sanitize_params
    # Recursively sanitize all string parameters
    sanitize_params_recursive(params)
  end

  def sanitize_params_recursive(parameters)
    parameters.each do |key, value|
      if value.is_a?(String)
        # Remove any potentially dangerous HTML/JS
        parameters[key] = ActionController::Base.helpers.sanitize(value, tags: [], attributes: [])

        # Additional sanitization for specific fields
        if key.to_s.include?("email")
          parameters[key] = sanitize_email(value)
        elsif key.to_s.include?("url") || key.to_s.include?("website")
          parameters[key] = sanitize_url(value)
        elsif key.to_s.include?("phone")
          parameters[key] = sanitize_phone(value)
        end
      elsif value.is_a?(ActionController::Parameters) || value.is_a?(Hash)
        sanitize_params_recursive(value)
      elsif value.is_a?(Array)
        value.each { |item| sanitize_params_recursive(item) if item.is_a?(Hash) || item.is_a?(ActionController::Parameters) }
      end
    end
  end

  def sanitize_email(email)
    # Basic email sanitization
    email.to_s.strip.downcase.gsub(/[^a-z0-9@.\-_+]/, "")
  end

  def sanitize_url(url)
    # Ensure URL is valid and safe

    uri = URI.parse(url)
    # Only allow http/https
    if uri.scheme&.match?(/^https?$/)
      url
    else
      ""
    end
  rescue URI::InvalidURIError
    ""
  end

  def sanitize_phone(phone)
    # Remove everything except digits, +, -, and spaces
    phone.to_s.gsub(/[^0-9+\-\s()]/, "")
  end

  # Method to validate file uploads
  def validate_file_upload(file_param, allowed_types: nil, max_size: 10.megabytes)
    return true unless file_param.present?

    # Check file size
    if file_param.size > max_size
      errors.add(:base, "File size exceeds maximum allowed (#{max_size / 1.megabyte}MB)")
      return false
    end

    # Check file type if restrictions provided
    if allowed_types.present?
      content_type = file_param.content_type
      extension = File.extname(file_param.original_filename).downcase

      unless allowed_types.any? { |type| content_type.include?(type) || extension == ".#{type}" }
        errors.add(:base, "File type not allowed. Allowed types: #{allowed_types.join(", ")}")
        return false
      end
    end

    # Scan for malware (if ClamAV is available)
    # if defined?(ClamScan)
    #   scan_result = ClamScan.scan(file_param.tempfile)
    #   unless scan_result.safe?
    #     errors.add(:base, "File failed security scan")
    #     return false
    #   end
    # end

    true
  end

  # Verify webhook signatures
  def verify_webhook_signature(payload, signature_header, secret)
    expected_signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      secret,
      payload
    )

    # Use secure comparison to prevent timing attacks
    ActiveSupport::SecurityUtils.secure_compare(signature_header, "sha256=#{expected_signature}")
  end

  # Log security events
  def log_security_event(event_type, details = {})
    Rails.logger.warn("[SECURITY] #{event_type}: #{details.merge(
      ip: request.remote_ip,
      user_id: current_user&.id,
      path: request.fullpath,
      user_agent: request.user_agent
    ).to_json}")

    # You could also send to monitoring service
    # Honeybadger.notify(event_type, context: details) if defined?(Honeybadger)
  end
end
