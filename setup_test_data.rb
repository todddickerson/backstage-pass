# Create test user if doesn't exist
test_user = User.find_or_create_by(email: 'test@backstagepass.app') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.first_name = 'Test'
  u.last_name = 'User'
end

# Create team for test user if doesn't have one
if test_user.teams.empty?
  team = Team.create!(name: 'Test Creator Team')
  test_user.memberships.create!(team: team, user_email: test_user.email)
  puts "Created team: #{team.name}"
else
  team = test_user.teams.first
  puts "Using existing team: #{team.name}"
end

# Create/find space for the team
space = team.spaces.first || Space.create!(
  team: team,
  name: 'Test Creator Space',
  description: 'A test space for streaming',
  slug: 'test-creator'
)
puts "Space: #{space.name} (slug: #{space.slug})"

# Create experience
experience = space.experiences.find_or_create_by(name: 'Live Streaming Test') do |e|
  e.description = 'Testing live streaming features'
  e.experience_type = 'live_stream'
  e.price_cents = 0  # Free for testing
  e.team = team
end
puts "Experience: #{experience.name}"

# Create stream
stream = experience.streams.find_or_create_by(title: 'Test Stream Session') do |s|
  s.description = 'Test stream for video player'
  s.scheduled_at = 1.hour.from_now
  s.status = 'scheduled'
  s.experience = experience
  # team is accessed through experience->space->team
end
puts "Stream created: #{stream.title} (ID: #{stream.id})"

# Create a second test user (viewer)
viewer_user = User.find_or_create_by(email: 'viewer@backstagepass.app') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.first_name = 'Viewer'
  u.last_name = 'User'
end
puts "Viewer user: #{viewer_user.email}"

puts "\nTest data setup complete!"
puts "Login as:"
puts "  Creator: test@backstagepass.app / password123"
puts "  Viewer: viewer@backstagepass.app / password123"
puts "\nStream URL: /account/streams/#{stream.id}"