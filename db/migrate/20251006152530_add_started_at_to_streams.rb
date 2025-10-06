class AddStartedAtToStreams < ActiveRecord::Migration[8.0]
  def change
    add_column :streams, :started_at, :datetime
  end
end
