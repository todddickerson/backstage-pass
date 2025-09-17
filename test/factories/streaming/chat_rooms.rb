FactoryBot.define do
  factory :streaming_chat_room, class: "Streaming::ChatRoom" do
    association :stream
    channel_id { "chat_#{SecureRandom.hex(4)}" }
  end
end
