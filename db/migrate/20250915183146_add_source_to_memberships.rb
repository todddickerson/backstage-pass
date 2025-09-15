class AddSourceToMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :source, :string
  end
end
