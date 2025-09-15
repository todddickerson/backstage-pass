class AddUserAndPurchasableToAccessPasses < ActiveRecord::Migration[8.0]
  def change
    add_reference :access_passes, :user, null: false, foreign_key: true
    add_reference :access_passes, :purchasable, polymorphic: true, null: false
  end
end
