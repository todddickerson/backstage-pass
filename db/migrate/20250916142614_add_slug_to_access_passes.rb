class AddSlugToAccessPasses < ActiveRecord::Migration[8.0]
  def change
    add_column :access_passes, :slug, :string
    add_index :access_passes, :slug
    add_index :access_passes, [:space_id, :slug], unique: true
  end
end
