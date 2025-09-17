class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.string :ip_address
      t.text :user_agent
      t.json :params
      t.datetime :performed_at

      t.timestamps
    end
  end
end
