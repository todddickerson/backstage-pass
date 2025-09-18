class AddCustomQuestionsToAccessPasses < ActiveRecord::Migration[8.0]
  def change
    add_column :access_passes, :custom_questions, :jsonb
  end
end
