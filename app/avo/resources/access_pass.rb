class Avo::Resources::AccessPass < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :team, as: :belongs_to
    field :status, as: :text
    field :expires_at, as: :date_time
  end
end
