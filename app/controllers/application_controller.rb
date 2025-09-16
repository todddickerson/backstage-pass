class ApplicationController < ActionController::Base
  include Controllers::Base
  include SecurityHeaders
  include DeviceDetection

  protect_from_forgery with: :exception, prepend: true
  
  # Additional security configurations
  
  # Prevent parameter pollution
  before_action :prevent_parameter_pollution
  
  # Audit sensitive actions
  after_action :audit_sensitive_actions, if: :audit_required?
  
  private
  
  def prevent_parameter_pollution
    # Remove duplicate parameters (keep first occurrence)
    params.each do |key, value|
      if value.is_a?(Array) && !key.to_s.end_with?("[]")
        params[key] = value.first
      end
    end
  end
  
  def audit_sensitive_actions
    # Log sensitive actions for audit trail
    if audit_required?
      AuditLog.create!(
        user: current_user,
        action: "#{controller_name}##{action_name}",
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        params: filtered_params_for_audit,
        performed_at: Time.current
      )
    end
  end
  
  def audit_required?
    # Define which actions require audit logging
    sensitive_actions = {
      "purchases" => %w[create],
      "access_passes" => %w[create update destroy],
      "streams" => %w[create destroy],
      "users" => %w[update destroy],
      "teams" => %w[update destroy],
      "billing" => :all
    }
    
    controller = controller_name.to_s
    action = action_name.to_s
    
    return false unless user_signed_in?
    
    if sensitive_actions[controller] == :all
      true
    elsif sensitive_actions[controller].is_a?(Array)
      sensitive_actions[controller].include?(action)
    else
      false
    end
  end
  
  def filtered_params_for_audit
    # Filter sensitive data from audit logs
    params.except(:password, :password_confirmation, :credit_card, :cvv, :ssn).to_unsafe_h
  end
end
