FactoryBot.define do
  factory :streaming_chat_room, class: 'Streaming::ChatRoom' do
    association :stream
    stream_id { nil }
    channel_id { nil }
  end
end
