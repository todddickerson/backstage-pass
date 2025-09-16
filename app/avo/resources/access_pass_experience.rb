class Avo::Resources::AccessPassExperience < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :access_pass, as: :belongs_to
    field :experience, as: :text
    field :included, as: :boolean
    field :position, as: :number
  end
end
