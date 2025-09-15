require "test_helper"

class SpaceTest < ActiveSupport::TestCase
  def setup
    @space = build(:space)
    @user = create(:user)
  end

  test "should be valid with valid attributes" do
    assert @space.valid?
  end

  test "should require name" do
    @space.name = nil
    assert_not @space.valid?
    assert_includes @space.errors[:name], "can't be blank"
  end

  test "should validate unique slug per team" do
    space1 = create(:space, slug: "test-space")
    space2 = build(:space, slug: "test-space", team: space1.team)
    assert_not space2.valid?
    assert_includes space2.errors[:slug], "has already been taken"
  end

  test "should generate slug from name if blank" do
    space = build(:space, slug: nil, name: "My Awesome Space")
    space.valid?
    assert_equal "my-awesome-space", space.slug
  end

  test "should check access for team members" do
    space = create(:space)
    team_member = create(:user)
    space.team.memberships.create!(user: team_member, role_ids: [])
    
    assert space.can_access?(team_member)
  end
end
