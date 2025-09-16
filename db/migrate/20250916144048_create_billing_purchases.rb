class CreateBillingPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_purchases do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :access_pass, null: true, foreign_key: true
      t.integer :amount_cents
      t.string :stripe_charge_id
      t.string :stripe_payment_intent_id
      t.string :status

      t.timestamps
    end
  end
end
