class CreateStreams < ActiveRecord::Migration[8.0]
  def change
    create_table :streams do |t|
      t.references :experience, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.datetime :scheduled_at
      t.string :status

      t.timestamps
    end
  end
end
