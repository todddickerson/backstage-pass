class RenameAccessPassToAccessGrant < ActiveRecord::Migration[8.0]
  def change
    # Rename the table from access_passes to access_grants
    rename_table :access_passes, :access_grants
    
    # Update any indexes that reference the old table name
    # (Rails should handle this automatically with rename_table)
  end
end
