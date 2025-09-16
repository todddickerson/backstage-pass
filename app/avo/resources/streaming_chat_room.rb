class Avo::Resources::StreamingChatRoom < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Streaming::ChatRoom
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :stream, as: :belongs_to
    field :stream_id, as: :belongs_to
    field :channel_id, as: :belongs_to
  end
end
