class AddWaitlistEntriesCountToAccessPasses < ActiveRecord::Migration[8.0]
  def change
    add_column :access_passes, :waitlist_entries_count, :integer, default: 0, null: false
    add_index :access_passes, :waitlist_entries_count
  end
end
