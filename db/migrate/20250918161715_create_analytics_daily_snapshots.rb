class CreateAnalyticsDailySnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_daily_snapshots do |t|
      t.references :team, null: false, foreign_key: true
      t.date :date
      t.references :space, null: true, foreign_key: true
      t.integer :total_revenue_cents
      t.integer :purchases_count
      t.integer :active_passes_count
      t.integer :stream_views
      t.integer :chat_messages

      t.timestamps
    end
  end
end
