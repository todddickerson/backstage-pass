class AddStripeIdsToAccessPasses < ActiveRecord::Migration[8.0]
  def change
    add_column :access_passes, :stripe_product_id, :string
    add_column :access_passes, :stripe_monthly_price_id, :string
    add_column :access_passes, :stripe_yearly_price_id, :string
  end
end
