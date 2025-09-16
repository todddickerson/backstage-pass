puts "🌱 Generating development environment seeds."

# Backstage Pass Platform - Development Seeds
# Following Bullet Train conventions for multi-tenant applications
#
# This file uses:
# - Idempotent operations with find_or_create_by
# - Faker for realistic test data  
# - Proper team/membership hierarchy
# - obfuscated_id for all route references

puts "\n🚀 Loading development seeds for Backstage Pass Platform..."
puts "=" * 50

# Helper method for consistent password in development
def dev_password
  'password123'
end

# ==========================================
# STEP 1: Create Teams and Users
# ==========================================
puts "\n👥 Creating teams and users..."

# Creator team with streaming capabilities
creator_user = User.find_or_create_by(email: 'creator@backstagepass.app') do |u|
  u.password = dev_password
  u.password_confirmation = dev_password
  u.first_name = 'Alex'
  u.last_name = 'Creator'
  puts "  ✅ Created creator user: #{u.email}"
end

# Find or create team for creator
creator_team = creator_user.teams.first || begin
  team = Team.create!(name: 'Creator Studio')
  creator_user.memberships.create!(
    team: team,
    user_email: creator_user.email,
    user_first_name: creator_user.first_name,
    user_last_name: creator_user.last_name
  )
  puts "  ✅ Created team: #{team.name}"
  team
end

# Create additional team members (for testing team features)
moderator_user = User.find_or_create_by(email: 'moderator@backstagepass.app') do |u|
  u.password = dev_password
  u.password_confirmation = dev_password
  u.first_name = 'Sam'
  u.last_name = 'Moderator'
  puts "  ✅ Created moderator user: #{u.email}"
end

# Add moderator to creator's team if not already a member
unless moderator_user.teams.include?(creator_team)
  moderator_user.memberships.create!(
    team: creator_team,
    user_email: moderator_user.email,
    user_first_name: moderator_user.first_name,
    user_last_name: moderator_user.last_name
  )
  puts "  ✅ Added moderator to creator team"
end

# Create viewer users (for testing access control)
viewer_users = []
3.times do |i|
  viewer_users << User.find_or_create_by(email: "viewer#{i+1}@backstagepass.app") do |u|
    u.password = dev_password
    u.password_confirmation = dev_password
    u.first_name = Faker::Name.first_name
    u.last_name = Faker::Name.last_name
    puts "  ✅ Created viewer user: #{u.email}"
  end
end

# ==========================================
# STEP 2: Create Spaces
# ==========================================
puts "\n🏠 Creating spaces..."

# Main creator space
creator_space = creator_team.spaces.first || Space.create!(
  team: creator_team,
  name: "#{creator_team.name} Space",
  description: "Premium live streaming and exclusive content from #{creator_team.name}",
  slug: 'creator-studio'
)
puts "  ✅ Space: #{creator_space.name}"
puts "     - Obfuscated ID: #{creator_space.obfuscated_id}"
puts "     - Slug: #{creator_space.slug}"

# ==========================================
# STEP 3: Create Experiences
# ==========================================
puts "\n🎭 Creating experiences..."

# Live streaming experience
streaming_experience = creator_space.experiences.find_or_create_by(
  name: 'Weekly Live Sessions'
) do |e|
  e.description = 'Interactive live streaming sessions every week with Q&A'
  e.experience_type = 'live_stream'
  e.price_cents = 2999 # $29.99
  e.team = creator_team
  puts "  ✅ Created live streaming experience: #{e.name}"
end

# Free experience (for testing)
free_experience = creator_space.experiences.find_or_create_by(
  name: 'Free Preview Stream'
) do |e|
  e.description = 'Free preview of our premium content'
  e.experience_type = 'live_stream'
  e.price_cents = 0 # Free
  e.team = creator_team
  puts "  ✅ Created free experience: #{e.name}"
end

# ==========================================
# STEP 4: Create Streams
# ==========================================
puts "\n📹 Creating streams..."

# Live stream (current) - simulating an active stream
live_stream = streaming_experience.streams.find_or_create_by(
  title: 'Live Now: Special Announcement'
) do |s|
  s.description = 'Special live stream with exciting announcements'
  s.scheduled_at = 1.hour.ago
  s.status = 'live'
  s.experience = streaming_experience
  puts "  ✅ Created live stream: #{s.title}"
end

# Test stream that's ready to go live
test_stream = streaming_experience.streams.find_or_create_by(
  title: 'Test Stream - Ready to Go Live'
) do |s|
  s.description = 'Test stream for video player functionality'
  s.scheduled_at = 5.minutes.from_now
  s.status = 'scheduled'
  s.experience = streaming_experience
  puts "  ✅ Created test stream: #{s.title}"
end

# Free preview stream
free_stream = free_experience.streams.find_or_create_by(
  title: 'Free Preview: Getting Started'
) do |s|
  s.description = 'Free introductory stream for new viewers'
  s.scheduled_at = 2.hours.from_now
  s.status = 'scheduled'
  s.experience = free_experience
  puts "  ✅ Created free stream: #{s.title}"
end

# ==========================================
# STEP 5: Create Access Passes (AccessGrants)
# ==========================================
puts "\n🎫 Creating access passes..."

# Give first viewer access to streaming experience
viewer_pass = AccessGrant.find_or_create_by(
  user: viewer_users[0],
  purchasable: streaming_experience
) do |ag|
  ag.status = 'active'
  ag.expires_at = 1.month.from_now
  puts "  ✅ Created access pass for #{viewer_users[0].email} to #{streaming_experience.name}"
end

# Give second viewer access to the entire space
space_pass = AccessGrant.find_or_create_by(
  user: viewer_users[1],
  purchasable: creator_space
) do |ag|
  ag.status = 'active'
  ag.expires_at = 3.months.from_now
  puts "  ✅ Created space-wide access pass for #{viewer_users[1].email}"
end

# ==========================================
# STEP 6: Create Creator Profiles
# ==========================================
puts "\n👤 Creating creator profiles..."

creator_profile = Creators::Profile.find_or_create_by(
  user: creator_user
) do |p|
  p.username = 'alexcreator'
  p.display_name = 'Alex Creator'
  p.bio = 'Professional content creator specializing in live streaming'
  p.website_url = 'https://alexcreator.com'
  puts "  ✅ Created creator profile: @#{p.username}"
end

# ==========================================
# SUMMARY
# ==========================================
puts "\n" + "=" * 50
puts "✅ DEVELOPMENT SEEDING COMPLETE!"
puts "=" * 50

puts "\n🔐 Test Accounts:"
puts "  Creator: creator@backstagepass.app / #{dev_password}"
puts "  Moderator: moderator@backstagepass.app / #{dev_password}"
puts "  Viewer 1: viewer1@backstagepass.app / #{dev_password} (has streaming access)"
puts "  Viewer 2: viewer2@backstagepass.app / #{dev_password} (has space access)"
puts "  Viewer 3: viewer3@backstagepass.app / #{dev_password} (no access)"

puts "\n🔗 Test URLs (using obfuscated_id for Bullet Train routing):"
puts "  Live Stream: /account/streams/#{live_stream.obfuscated_id}"
puts "  Test Stream: /account/streams/#{test_stream.obfuscated_id}"
puts "  Free Stream: /account/streams/#{free_stream.obfuscated_id}"

puts "\n🎥 Video Streaming Test:"
puts "  1. Login as creator@backstagepass.app"
puts "  2. Visit /account/streams/#{test_stream.obfuscated_id}"
puts "  3. Click 'Start Live Stream' to test LiveKit integration"
puts "  4. Open another browser as viewer1 to test viewing"

puts "\n🎉 Development environment ready for testing!"
