#!/usr/bin/env ruby
require_relative "config/environment"

puts "Testing basic model creation..."

begin
  # Test user creation
  user = User.create!(
    first_name: "Test",
    last_name: "Creator",
    email: "test-creator-#{SecureRandom.hex(4)}@example.com",
    password: "password123"
  )
  puts "✅ User created: #{user.email}"

  # Test team creation
  team = user.teams.create!(name: "Test Team")
  puts "✅ Team created: #{team.name}"

  # Get or create primary space (teams auto-create a primary space)
  space = team.spaces.first
  if space.nil?
    space = team.spaces.create!(
      name: "Primary Space",
      description: "Primary space for team",
      slug: "primary-space-#{SecureRandom.hex(4)}",
      published: true
    )
    puts "✅ Space created: #{space.name}"
  else
    space.update!(published: true) if !space.published?
    puts "✅ Space found: #{space.name}"
  end

  # Test experience creation
  experience = space.experiences.create!(
    name: "Test Experience",
    description: "Testing experience creation",
    experience_type: "live_stream",
    price_cents: 1999
  )
  puts "✅ Experience created: #{experience.name}"

  # Test stream creation
  stream = experience.streams.create!(
    title: "Test Stream",
    description: "Testing stream creation",
    scheduled_at: 1.hour.from_now,
    status: "scheduled"
  )
  puts "✅ Stream created: #{stream.title}"

  puts "🎉 All basic models working!"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end
