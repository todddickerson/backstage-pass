class Avo::Resources::AnalyticsDailySnapshot < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Analytics::DailySnapshot
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :team, as: :belongs_to
    field :date, as: :date
    field :space, as: :belongs_to
    field :total_revenue_cents, as: :number
    field :purchases_count, as: :number
    field :active_passes_count, as: :number
    field :stream_views, as: :number
    field :chat_messages, as: :number
  end
end
