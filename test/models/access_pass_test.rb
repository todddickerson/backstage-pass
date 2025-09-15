require "test_helper"

class AccessPassTest < ActiveSupport::TestCase
  def setup
    @team = create(:team)
    @space = create(:space, team: @team)
    @user = create(:user)
    @access_pass = build(:access_pass, user: @user, team: @team, purchasable: @space)
  end

  test "should be valid with valid attributes" do
    assert @access_pass.valid?
  end

  test "should require user" do
    @access_pass.user = nil
    assert_not @access_pass.valid?
    assert_includes @access_pass.errors[:user_id], "can't be blank"
  end

  test "should require purchasable" do
    @access_pass.purchasable = nil
    assert_not @access_pass.valid?
    assert_includes @access_pass.errors[:purchasable_id], "can't be blank"
  end

  test "should default to active status" do
    access_pass = AccessPass.new
    access_pass.valid? # trigger before_validation callback
    assert_equal 'active', access_pass.status
  end

  test "should be active when status is active and not expired" do
    @access_pass.status = 'active'
    @access_pass.expires_at = 1.month.from_now
    assert @access_pass.active?
  end

  test "should not be active when expired" do
    @access_pass.status = 'active'
    @access_pass.expires_at = 1.week.ago
    assert_not @access_pass.active?
  end
end
