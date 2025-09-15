# DualIdFinder: Controller concern for handling both FriendlyId slugs and obfuscated IDs
# 
# This concern provides helper methods for controllers to find records using either
# slug-based or obfuscated ID lookups depending on the context.
#
# Usage in controllers:
#   class PublicSpacesController < ApplicationController
#     include DualIdFinder
#
#     def show
#       @space = find_resource(Space, params[:id], prefer_slug: true)
#     end
#   end

module DualIdFinder
  extend ActiveSupport::Concern

  private

  # Find a resource by any supported ID format
  # @param model_class [Class] The ActiveRecord model class
  # @param id [String] The ID/slug to find
  # @param prefer_slug [Boolean] Whether to prefer slug lookup for URLs
  # @param admin_context [Boolean] Whether this is an admin operation
  def find_resource(model_class, id, prefer_slug: false, admin_context: false)
    return nil if id.blank?

    if admin_context && model_class.respond_to?(:find_for_admin)
      model_class.find_for_admin(id)
    elsif model_class.respond_to?(:find_by_any_id)
      model_class.find_by_any_id(id)
    else
      model_class.find(id)
    end
  rescue ActiveRecord::RecordNotFound => e
    # Log the lookup failure for debugging
    Rails.logger.debug "DualIdFinder: Failed to find #{model_class.name} with ID '#{id}': #{e.message}"
    raise e
  end

  # Check if an ID looks like a slug vs an obfuscated ID
  def looks_like_slug?(id)
    return false if id.blank?
    
    # Slugs typically contain hyphens and lowercase letters
    # Obfuscated IDs are typically mixed case without hyphens
    id.include?('-') && id.downcase == id
  end

  # Check if an ID looks like an obfuscated ID
  def looks_like_obfuscated_id?(id)
    return false if id.blank?
    
    # Obfuscated IDs are typically 6+ chars, mixed case, no hyphens
    id.length >= 6 && id.match?(/[A-Z]/) && id.match?(/[a-z]/) && !id.include?('-')
  end

  # Generate the appropriate URL parameter for a record
  def url_param_for(record, context: :public)
    return record.id if record.blank?

    case context
    when :admin
      record.respond_to?(:admin_param) ? record.admin_param : record.id
    when :public
      record.respond_to?(:to_param) ? record.to_param : record.id
    else
      record.to_param
    end
  end
end