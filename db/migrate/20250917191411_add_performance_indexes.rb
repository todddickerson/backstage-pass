class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Performance indexes for common query patterns

    # Experiences - frequently queried by space and type
    add_index :experiences, [:space_id, :experience_type], algorithm: :concurrently unless index_exists?(:experiences, [:space_id, :experience_type])
    add_index :experiences, [:space_id, :created_at], algorithm: :concurrently unless index_exists?(:experiences, [:space_id, :created_at])

    # Streams - queried by experience and status for real-time features
    add_index :streams, [:experience_id, :status], algorithm: :concurrently unless index_exists?(:streams, [:experience_id, :status])
    add_index :streams, [:status, :scheduled_at], algorithm: :concurrently unless index_exists?(:streams, [:status, :scheduled_at])

    # Access Grants - critical for authorization checks
    add_index :access_grants, [:user_id, :expires_at], algorithm: :concurrently unless index_exists?(:access_grants, [:user_id, :expires_at])
    add_index :access_grants, [:access_pass_id, :created_at], algorithm: :concurrently unless index_exists?(:access_grants, [:access_pass_id, :created_at])

    # Spaces - slug lookups are common
    add_index :spaces, :slug, algorithm: :concurrently unless index_exists?(:spaces, :slug)
    add_index :spaces, [:team_id, :created_at], algorithm: :concurrently unless index_exists?(:spaces, [:team_id, :created_at])

    # Teams - user association lookups
    add_index :teams, :created_at, algorithm: :concurrently unless index_exists?(:teams, :created_at)

    # Chat Rooms - stream relationship critical for real-time
    add_index :chat_rooms, :stream_id, algorithm: :concurrently if table_exists?(:chat_rooms) && !index_exists?(:chat_rooms, :stream_id)

    # Access Passes - pricing and space queries
    add_index :access_passes, [:space_id, :price_cents], algorithm: :concurrently unless index_exists?(:access_passes, [:space_id, :price_cents])
    add_index :access_passes, [:pricing_type, :created_at], algorithm: :concurrently unless index_exists?(:access_passes, [:pricing_type, :created_at])

    # Memberships - user-team relationship critical for authorization
    add_index :memberships, [:user_id, :team_id], unique: true, algorithm: :concurrently unless index_exists?(:memberships, [:user_id, :team_id])
    add_index :memberships, [:team_id, :role_ids], algorithm: :concurrently unless index_exists?(:memberships, [:team_id, :role_ids])
  end
end
