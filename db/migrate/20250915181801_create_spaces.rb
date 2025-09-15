class CreateSpaces < ActiveRecord::Migration[8.0]
  def change
    create_table :spaces do |t|
      t.references :team, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :slug
      t.boolean :published, default: false

      t.timestamps
    end
  end
end
