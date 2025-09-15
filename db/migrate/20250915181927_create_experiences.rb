class CreateExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :experiences do |t|
      t.references :space, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :experience_type
      t.integer :price_cents

      t.timestamps
    end
  end
end
