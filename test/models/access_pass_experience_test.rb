require "test_helper"

class AccessPassExperienceTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:onboarded_user)
    @team = @user.current_team
    @space = @team.primary_space
    @access_pass = AccessPass.create!(
      space: @space,
      name: "Premium Pass",
      pricing_type: "one_time",
      price_cents: 9900,
      published: true
    )
    @experience = Experience.create!(
      space: @space,
      name: "VIP Live Stream",
      experience_type: "live_stream",
      price_cents: 4900
    )
  end

  test "should create valid access pass experience" do
    access_pass_experience = AccessPassExperience.new(
      access_pass: @access_pass,
      experience: @experience,
      included: true,
      position: 1
    )
    assert access_pass_experience.valid?
  end

  test "should require access pass" do
    access_pass_experience = AccessPassExperience.new(
      experience: @experience,
      included: true
    )
    assert_not access_pass_experience.valid?
    assert_includes access_pass_experience.errors[:access_pass], "must exist"
  end

  test "should require experience" do
    access_pass_experience = AccessPassExperience.new(
      access_pass: @access_pass,
      included: true
    )
    assert_not access_pass_experience.valid?
    assert_includes access_pass_experience.errors[:experience], "must exist"
  end

  test "should have included default to true" do
    access_pass_experience = AccessPassExperience.create!(
      access_pass: @access_pass,
      experience: @experience
    )
    assert access_pass_experience.included?
  end

  test "should allow position to be set" do
    access_pass_experience = AccessPassExperience.create!(
      access_pass: @access_pass,
      experience: @experience,
      position: 5
    )
    assert_equal 5, access_pass_experience.position
  end

  test "should be destroyed when access pass is destroyed" do
    AccessPassExperience.create!(
      access_pass: @access_pass,
      experience: @experience
    )

    assert_difference "AccessPassExperience.count", -1 do
      @access_pass.destroy
    end
  end

  test "should associate access pass with experiences through join table" do
    @access_pass.experiences << @experience

    assert_includes @access_pass.experiences, @experience
    assert_includes @experience.access_passes, @access_pass
  end
end
