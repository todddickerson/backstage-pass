# DualIdSupport: Enables models to use both FriendlyId slugs and Bullet Train obfuscated IDs
#
# This concern resolves the conflict between FriendlyId and ObfuscatesId by:
# 1. Allowing FriendlyId to handle public-facing URLs with human-readable slugs
# 2. Providing obfuscated IDs for admin interfaces and secure operations
# 3. Supporting lookup by both slug and obfuscated ID formats
#
# Usage:
#   class Space < ApplicationRecord
#     include DualIdSupport
#
#     extend FriendlyId
#     friendly_id :slug, use: :slugged
#   end

module DualIdSupport
  extend ActiveSupport::Concern

  included do
    # Override to_param to prefer slug for public URLs, but provide obfuscated_id fallback
    def to_param
      if respond_to?(:slug) && slug.present?
        slug
      elsif respond_to?(:obfuscated_id)
        obfuscated_id
      else
        super
      end
    end

    # Add method to explicitly get obfuscated ID for admin use
    def admin_param
      if respond_to?(:obfuscated_id)
        obfuscated_id
      else
        id.to_s
      end
    end

    # Add method to check if this record uses slugs
    def uses_friendly_id?
      respond_to?(:slug) && slug.present?
    end
  end

  class_methods do
    # Enhanced finder that tries multiple ID formats:
    # 1. First try FriendlyId.friendly.find (handles slugs and integer IDs)
    # 2. If that fails and ObfuscatesId is available, try obfuscated ID decode
    # 3. Finally fallback to standard find
    def find_by_any_id(id)
      return find(id) if id.blank?

      # Try FriendlyId first (if available)
      if respond_to?(:friendly)
        begin
          return friendly.find(id)
        rescue ActiveRecord::RecordNotFound
          # Continue to try obfuscated ID
        end
      end

      # Try obfuscated ID (if available)
      if respond_to?(:decode_id)
        begin
          decoded_id = decode_id(id)
          # Call ActiveRecord's find directly to avoid recursion
          return where(id: decoded_id).first! if decoded_id.present?
        rescue
          # Continue to standard find
        end
      end

      # Fallback to standard ActiveRecord find by ID
      # Use where().first! to avoid our overridden find method
      where(id: id).first!
    end

    # NOTE: We don't override find() here because Bullet Train's ObfuscatesId
    # already overrides it. Instead, controllers should explicitly call
    # find_by_any_id() when they need slug/obfuscated ID support.

    # Admin-specific finder that prefers obfuscated IDs
    def find_for_admin(id)
      if respond_to?(:decode_id)
        begin
          decoded_id = decode_id(id)
          return super(decoded_id) if decoded_id.present?
        rescue
          # Fall through to other methods
        end
      end

      find_by_any_id(id)
    end
  end
end
