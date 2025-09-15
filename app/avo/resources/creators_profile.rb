class Avo::Resources::CreatorsProfile < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Creators::Profile
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :username, as: :text
    field :bio, as: :textarea
    field :display_name, as: :text
    field :website_url, as: :text
  end
end
