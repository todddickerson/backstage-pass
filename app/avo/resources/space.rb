class Avo::Resources::Space < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :team, as: :belongs_to
    field :name, as: :text
    field :description, as: :textarea
    field :slug, as: :text
    field :published, as: :boolean
  end
end
