class AddLivekitFieldsToStreams < ActiveRecord::Migration[8.0]
  def change
    add_column :streams, :livekit_room_name, :string
    add_column :streams, :livekit_room_sid, :string
    add_column :streams, :livekit_egress_id, :string
    add_column :streams, :viewer_count, :integer
    add_column :streams, :recording_url, :string
    add_column :streams, :max_viewers, :integer
  end
end
