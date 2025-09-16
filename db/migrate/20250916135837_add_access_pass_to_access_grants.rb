class AddAccessPassToAccessGrants < ActiveRecord::Migration[8.0]
  def change
    add_reference :access_grants, :access_pass, null: true, foreign_key: true
  end
end
