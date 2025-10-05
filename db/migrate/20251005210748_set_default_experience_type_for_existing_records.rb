class SetDefaultExperienceTypeForExistingRecords < ActiveRecord::Migration[8.0]
  def up
    # Set default experience_type for any experiences that have nil
    # Default to 'live_stream' since that's the primary use case
    Experience.where(experience_type: nil).update_all(experience_type: 'live_stream')
  end

  def down
    # No need to reverse - this is a data fix
  end
end
