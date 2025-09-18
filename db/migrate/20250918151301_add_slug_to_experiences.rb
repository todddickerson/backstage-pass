class AddSlugToExperiences < ActiveRecord::Migration[8.0]
  def change
    add_column :experiences, :slug, :string
    add_index :experiences, :slug
  end
end
