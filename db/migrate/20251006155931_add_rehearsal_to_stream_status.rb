class AddRehearsalToStreamStatus < ActiveRecord::Migration[8.0]
  def up
    # Rehearsal status already supported by string column, no schema change needed
    # Just documenting the new status in this migration
  end

  def down
    # No-op
  end
end
