class Avo::Resources::Stream < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :experience, as: :belongs_to
    field :title, as: :text
    field :description, as: :textarea
    field :scheduled_at, as: :date_time
    field :status, as: :text
  end
end
