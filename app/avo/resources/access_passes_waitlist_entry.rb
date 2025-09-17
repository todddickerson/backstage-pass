class Avo::Resources::AccessPassesWaitlistEntry < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::AccessPasses::WaitlistEntry
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :access_pass, as: :belongs_to
    field :email, as: :text
    field :first_name, as: :text
    field :last_name, as: :text
    field :answers, as: :textarea
    field :status, as: :text
    field :notes, as: :textarea
    field :approved_at, as: :date_time
    field :rejected_at, as: :date_time
  end
end
