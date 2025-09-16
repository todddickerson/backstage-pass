class CreateAccessPasses < ActiveRecord::Migration[8.0]
  def change
    create_table :access_passes do |t|
      t.references :space, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :slug
      t.string :pricing_type
      t.integer :price_cents
      t.integer :stock_limit
      t.boolean :waitlist_enabled
      t.boolean :published

      t.timestamps
    end
    
    add_index :access_passes, :slug
    add_index :access_passes, [:space_id, :slug], unique: true
  end
end
