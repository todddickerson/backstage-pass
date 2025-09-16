require "test_helper"

class ExperienceTest < ActiveSupport::TestCase
  def setup
    @experience = build(:experience)
  end

  test "should be valid with valid attributes" do
    assert @experience.valid?
  end

  test "should require name" do
    @experience.name = nil
    assert_not @experience.valid?
    assert_includes @experience.errors[:name], "can't be blank"
  end

  test "should require experience_type" do
    @experience.experience_type = nil
    assert_not @experience.valid?
    assert_includes @experience.errors[:experience_type], "can't be blank"
  end

  test "should recognize live streaming experience" do
    @experience.experience_type = "live_stream"
    assert @experience.live_streaming?
  end

  test "should format price display correctly" do
    @experience.price_cents = 999
    assert_equal "$9.99", @experience.price_display

    @experience.price_cents = 0
    assert_equal "Free", @experience.price_display
  end
end
