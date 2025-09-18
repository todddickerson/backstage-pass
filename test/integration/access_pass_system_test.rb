require "test_helper"

class AccessPassSystemTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:onboarded_user)
    @team = @user.current_team
    @space = @team.primary_space
    @space.update!(published: true)
  end

  test "access pass has correct pricing types" do
    # Test each pricing type
    %w[free one_time monthly yearly].each do |pricing_type|
      pass = @space.access_passes.create!(
        name: "#{pricing_type.titleize} Pass",
        pricing_type: pricing_type,
        price_cents: (pricing_type == "free") ? 0 : 1999,
        published: true
      )

      assert pass.valid?, "#{pricing_type} pass should be valid"
      assert_equal pricing_type, pass.pricing_type
    end
  end

  test "access pass price display formatting" do
    # Free pass
    free_pass = @space.access_passes.create!(
      name: "Free Pass",
      pricing_type: "free",
      price_cents: 0
    )
    assert_equal "Free", free_pass.price_display

    # One-time pass
    one_time = @space.access_passes.create!(
      name: "One Time",
      pricing_type: "one_time",
      price_cents: 2999
    )
    assert_equal "$29.99", one_time.price_display

    # Monthly pass
    monthly = @space.access_passes.create!(
      name: "Monthly",
      pricing_type: "monthly",
      price_cents: 999
    )
    assert_equal "$9.99/month", monthly.price_display

    # Yearly pass
    yearly = @space.access_passes.create!(
      name: "Yearly",
      pricing_type: "yearly",
      price_cents: 9999
    )
    assert_equal "$99.99/year", yearly.price_display
  end

  test "access pass can include multiple experiences" do
    # Create experiences
    stream = @space.experiences.create!(
      name: "Live Stream",
      experience_type: "live_stream",
      price_cents: 0
    )

    course = @space.experiences.create!(
      name: "Video Course",
      experience_type: "course",
      price_cents: 0
    )

    # Create access pass
    vip_pass = @space.access_passes.create!(
      name: "VIP All Access",
      pricing_type: "monthly",
      price_cents: 4999,
      published: true
    )

    # Associate experiences with pass
    vip_pass.access_pass_experiences.create!(experience: stream)
    vip_pass.access_pass_experiences.create!(experience: course)

    # Verify associations
    assert_equal 2, vip_pass.experiences.count
    assert_includes vip_pass.experiences, stream
    assert_includes vip_pass.experiences, course
  end

  test "access pass stock management" do
    # Unlimited stock
    unlimited = @space.access_passes.create!(
      name: "Unlimited",
      pricing_type: "one_time",
      price_cents: 999,
      stock_limit: nil,
      published: true
    )
    assert unlimited.unlimited_stock?
    assert unlimited.available?

    # Limited stock
    limited = @space.access_passes.create!(
      name: "Limited Edition",
      pricing_type: "one_time",
      price_cents: 4999,
      stock_limit: 10,
      published: true
    )
    assert_not limited.unlimited_stock?
    assert limited.available?

    # Out of stock
    sold_out = @space.access_passes.create!(
      name: "Sold Out",
      pricing_type: "one_time",
      price_cents: 999,
      stock_limit: 0,
      published: true
    )
    assert_not sold_out.available?
  end

  test "experience types and validation" do
    # Test each experience type
    types = %w[live_stream course community consultation digital_product]

    types.each do |type|
      experience = @space.experiences.create!(
        name: "#{type.humanize} Experience",
        experience_type: type,
        price_cents: 1999
      )

      assert experience.valid?, "#{type} experience should be valid"
      assert_equal type, experience.experience_type
    end
  end

  test "experience requires real time check" do
    stream = @space.experiences.create!(
      name: "Stream",
      experience_type: "live_stream",
      price_cents: 0
    )
    assert stream.requires_real_time?

    consultation = @space.experiences.create!(
      name: "Consultation",
      experience_type: "consultation",
      price_cents: 4999
    )
    assert consultation.requires_real_time?

    course = @space.experiences.create!(
      name: "Course",
      experience_type: "course",
      price_cents: 1999
    )
    assert_not course.requires_real_time?
  end

  test "access pass slug generation" do
    pass = @space.access_passes.create!(
      name: "Super VIP Access Pass",
      pricing_type: "monthly",
      price_cents: 2999
    )

    assert_equal "super-vip-access-pass", pass.slug
    assert_equal pass, @space.access_passes.friendly.find("super-vip-access-pass")
  end

  test "access pass waitlist enabled" do
    waitlist_pass = @space.access_passes.create!(
      name: "Exclusive Access",
      pricing_type: "yearly",
      price_cents: 99999,
      waitlist_enabled: true,
      stock_limit: 0,
      published: true
    )

    assert waitlist_pass.waitlist_enabled?
    assert_not waitlist_pass.available? # Out of stock but has waitlist
  end

  test "money-rails integration for pricing" do
    pass = @space.access_passes.create!(
      name: "Premium",
      pricing_type: "monthly",
      price_cents: 1999
    )

    # Test money object
    assert_equal 1999, pass.price_cents
    assert_equal Money.new(1999, "USD"), pass.price
    assert_equal "$19.99", pass.price.format
  end

  test "access pass and experience associations through space" do
    # Space should have access_passes
    assert_respond_to @space, :access_passes
    assert_respond_to @space, :experiences

    # Create test data
    pass = @space.access_passes.create!(
      name: "Space Pass",
      pricing_type: "monthly",
      price_cents: 999
    )

    experience = @space.experiences.create!(
      name: "Space Experience",
      experience_type: "live_stream",
      price_cents: 0
    )

    # Verify space associations
    assert_includes @space.access_passes, pass
    assert_includes @space.experiences, experience
  end
end
