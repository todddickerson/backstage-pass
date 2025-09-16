class CreateAccessPassExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :access_pass_experiences do |t|
      t.references :access_pass, null: false, foreign_key: true
      t.references :experience, null: false, foreign_key: true
      t.boolean :included, default: true
      t.integer :position

      t.timestamps
    end
  end
end
