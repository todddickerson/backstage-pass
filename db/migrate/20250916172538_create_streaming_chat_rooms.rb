class CreateStreamingChatRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :streaming_chat_rooms do |t|
      t.references :stream, null: false, foreign_key: true
      t.string :channel_id

      t.timestamps
    end

    add_index :streaming_chat_rooms, :channel_id, unique: true
  end
end
