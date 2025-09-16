class Avo::Resources::BillingPurchase < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Billing::Purchase
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :team, as: :belongs_to
    field :user, as: :belongs_to
    field :access_pass, as: :belongs_to
    field :amount_cents, as: :number
    field :stripe_charge_id, as: :belongs_to
    field :stripe_payment_intent_id, as: :belongs_to
    field :status, as: :text
  end
end
