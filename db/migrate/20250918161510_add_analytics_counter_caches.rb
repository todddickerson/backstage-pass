class AddAnalyticsCounterCaches < ActiveRecord::Migration[8.0]
  def change
    # Counter caches for Space model
    add_column :spaces, :purchases_count, :integer, default: 0, null: false
    add_column :spaces, :active_passes_count, :integer, default: 0, null: false
    add_column :spaces, :total_revenue_cents, :integer, default: 0, null: false

    # Counter caches for Stream model
    add_column :streams, :max_viewer_count, :integer, default: 0, null: false
    add_column :streams, :total_viewers, :integer, default: 0, null: false
    add_column :streams, :chat_messages_count, :integer, default: 0, null: false

    # Counter caches for AccessPass model (purchases_count already exists via access_grants counter_cache)
    # waitlist_entries_count will be added via counter_cache relationship

    # Add indexes for performance
    add_index :spaces, :purchases_count
    add_index :spaces, :total_revenue_cents
    add_index :streams, :max_viewer_count
    add_index :streams, :total_viewers
  end
end
