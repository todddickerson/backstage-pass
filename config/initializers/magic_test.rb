if defined?(MagicTest)
  MagicTest.config do |config|
    config.use_headless = ENV['HEADLESS'].present?
    config.save_recordings = true
    config.recordings_path = Rails.root.join('test/recordings')
    config.verbose = true
    config.generate_complete_test = true
  end
end
