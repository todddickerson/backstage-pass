class AddCounterCaches < ActiveRecord::Migration[8.0]
  def change
    # Counter caches to avoid COUNT queries
    
    # Spaces counter caches
    add_column :spaces, :experiences_count, :integer, default: 0, null: false
    add_column :spaces, :access_passes_count, :integer, default: 0, null: false
    
    # Experiences counter caches
    add_column :experiences, :streams_count, :integer, default: 0, null: false
    add_column :experiences, :access_grants_count, :integer, default: 0, null: false
    
    # Teams counter caches
    add_column :teams, :spaces_count, :integer, default: 0, null: false
    add_column :teams, :memberships_count, :integer, default: 0, null: false
    
    # Access Passes counter caches
    add_column :access_passes, :access_grants_count, :integer, default: 0, null: false
    
    # Streams counter caches (for chat messages if implemented)
    add_column :streams, :messages_count, :integer, default: 0, null: false if table_exists?(:messages)
    
    # Backfill existing counts
    reversible do |dir|
      dir.up do
        # Backfill spaces
        execute <<-SQL
          UPDATE spaces SET experiences_count = (
            SELECT COUNT(*) FROM experiences WHERE experiences.space_id = spaces.id
          )
        SQL
        
        execute <<-SQL
          UPDATE spaces SET access_passes_count = (
            SELECT COUNT(*) FROM access_passes WHERE access_passes.space_id = spaces.id
          )
        SQL
        
        # Backfill experiences
        execute <<-SQL
          UPDATE experiences SET streams_count = (
            SELECT COUNT(*) FROM streams WHERE streams.experience_id = experiences.id
          )
        SQL
        
        # Backfill teams
        execute <<-SQL
          UPDATE teams SET spaces_count = (
            SELECT COUNT(*) FROM spaces WHERE spaces.team_id = teams.id
          )
        SQL
        
        execute <<-SQL
          UPDATE teams SET memberships_count = (
            SELECT COUNT(*) FROM memberships WHERE memberships.team_id = teams.id
          )
        SQL
        
        # Backfill access passes
        execute <<-SQL
          UPDATE access_passes SET access_grants_count = (
            SELECT COUNT(*) FROM access_grants WHERE access_grants.access_pass_id = access_passes.id
          )
        SQL
      end
    end
  end
end
