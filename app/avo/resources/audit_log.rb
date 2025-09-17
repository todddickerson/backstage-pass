class Avo::Resources::AuditLog < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :action, as: :text
    field :ip_address, as: :text
    field :user_agent, as: :textarea
    field :params, as: :code
    field :performed_at, as: :date_time
  end
end
