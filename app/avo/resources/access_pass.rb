class Avo::Resources::AccessPass < Avo::BaseResource
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
    field :pricing_type, as: :text
    field :price_cents, as: :number
    field :stock_limit, as: :number
    field :waitlist_enabled, as: :boolean
    field :published, as: :boolean
  end
end
