class AddLastBroadcasterSeenAtToStreams < ActiveRecord::Migration[8.0]
  def change
    add_column :streams, :last_broadcaster_seen_at, :datetime
  end
end
