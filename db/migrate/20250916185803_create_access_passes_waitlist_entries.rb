class CreateAccessPassesWaitlistEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :access_passes_waitlist_entries do |t|
      t.references :access_pass, null: false, foreign_key: true
      t.string :email
      t.string :first_name
      t.string :last_name
      t.text :answers
      t.string :status
      t.text :notes
      t.datetime :approved_at
      t.datetime :rejected_at

      t.timestamps
    end
  end
end
