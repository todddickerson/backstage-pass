class AddUserToWaitlistEntries < ActiveRecord::Migration[8.0]
  def change
    add_reference :access_passes_waitlist_entries, :user, null: true, foreign_key: true
  end
end
