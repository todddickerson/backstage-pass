require "test_helper"

class CreatorSetupFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:onboarded_user)
    @team = @user.current_team
  end

  test "team automatically gets a default space on creation" do
    # Team should have a space created automatically
    assert_equal 1, @team.spaces.count, "Team should have exactly one space"
    
    space = @team.primary_space
    assert_not_nil space, "Team should have a primary space"
    assert_equal "#{@team.name}'s Space", space.name
    assert_equal @team.name.parameterize, space.slug
    assert_not space.published?, "Space should not be published by default"
  end

  test "creator profile can be accessed via username route" do
    # Create a creator profile
    profile = Creators::Profile.create!(
      user: @user,
      username: "testcreator",
      display_name: "Test Creator",
      bio: "Test bio"
    )

    # Try to access the creator profile page
    get creator_profile_path(username: "testcreator")
    
    # Should redirect to coming soon page since space isn't published
    assert_response :success
    assert_select "body", /coming soon/i
  end

  test "published space can be accessed via slug route" do
    space = @team.primary_space
    space.update!(published: true)

    # Access the space via its slug
    get public_space_path(space_slug: space.slug)
    assert_response :success
    assert_select "h1", text: space.name
  end

  test "unpublished space returns 404" do
    space = @team.primary_space
    space.update!(published: false)

    # Try to access unpublished space
    assert_raises(ActiveRecord::RecordNotFound) do
      get public_space_path(space_slug: space.slug)
    end
  end

  test "creator profile redirects to space when published" do
    # Create profile and publish space
    profile = Creators::Profile.create!(
      user: @user,
      username: "activecreator",
      display_name: "Active Creator"
    )
    
    space = @team.primary_space
    space.update!(published: true)

    # Access creator profile
    get creator_profile_path(username: "activecreator")
    
    # Should redirect to the published space
    assert_redirected_to public_space_path(space.slug)
  end

  test "space validates unique slug per team" do
    space1 = @team.primary_space
    
    # Create another team and space
    other_team = create(:team)
    space2 = other_team.primary_space
    
    # Try to use the same slug - should be valid since different teams
    space2.slug = space1.slug
    assert space2.valid?, "Same slug should be valid for different teams"
    
    # Try to create another space with same slug in same team (when enabled)
    if @team.spaces.count < 2 # Only if multiple spaces allowed
      duplicate = @team.spaces.build(name: "Duplicate", slug: space1.slug)
      assert_not duplicate.valid?, "Duplicate slug in same team should be invalid"
    end
  end
end