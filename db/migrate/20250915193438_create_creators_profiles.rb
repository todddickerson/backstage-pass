class CreateCreatorsProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :creators_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :username
      t.text :bio
      t.string :display_name
      t.string :website_url

      t.timestamps
    end
  end
end
