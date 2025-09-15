class Avo::Resources::Experience < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :space, as: :belongs_to
    field :name, as: :text
    field :description, as: :textarea
    field :experience_type, as: :text
    field :price_cents, as: :number
  end
end
