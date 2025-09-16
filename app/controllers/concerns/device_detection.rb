# app/controllers/concerns/device_detection.rb
require "device_detector"

module DeviceDetection
  extend ActiveSupport::Concern

  included do
    before_action :detect_device_variant
    helper_method :hotwire_native_app?, :ios_app?, :android_app?, :mobile_app?, :platform
  end

  private

  def detect_device_variant
    @device = ::DeviceDetector.new(request.user_agent)
    
    # Set variant for view rendering
    request.variant = :hotwire_native if hotwire_native_app?
    request.variant = :mobile if mobile_app? && !hotwire_native_app?
  end

  def hotwire_native_app?
    # Check for Hotwire Native user agent identifiers
    return true if request.user_agent.to_s.match?(/Turbo Native|Hotwire Native/i)
    
    # Also check for custom header that native apps can send
    request.headers["X-Hotwire-Native-Version"].present?
  end

  def ios_app?
    hotwire_native_app? && @device&.os_name == "iOS"
  end

  def android_app?
    hotwire_native_app? && @device&.os_name == "Android"
  end

  def mobile_app?
    @device&.device_type == "smartphone" || @device&.device_type == "tablet"
  end

  def platform
    return "ios" if ios_app?
    return "android" if android_app?
    return "mobile" if mobile_app?
    "web"
  end
end