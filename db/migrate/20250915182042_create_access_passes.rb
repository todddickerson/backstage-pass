class CreateAccessPasses < ActiveRecord::Migration[8.0]
  def change
    create_table :access_passes do |t|
      t.references :team, null: false, foreign_key: true
      t.string :status
      t.datetime :expires_at

      t.timestamps
    end
  end
end
