require "test_helper"

class TeamSpaceManagementFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:onboarded_user)
    @team = @user.current_team
    sign_in @user
  end

  test "user can create a new team" do
    # Navigate to teams page (may redirect to current team)
    get account_teams_path
    assert_includes [200, 302], response.status, "Teams page should be accessible or redirect"

    # Create new team
    assert_difference "Team.count", 1 do
      post account_teams_path, params: {
        team: {
          name: "New Test Team"
        }
      }
    end

    team = Team.last
    assert_equal "New Test Team", team.name

    # Reload user to pick up any new associations
    @user.reload

    # User should be a member of the new team
    assert @user.teams.include?(team), "User should be a member of the newly created team. User teams: #{@user.teams.pluck(:name)}, New team: #{team.name}"

    # User should have admin role in the new team
    membership = @user.memberships.find_by(team: team)
    assert_not_nil membership
    assert_includes membership.role_ids, "admin"

    follow_redirect!
    assert_response :success
  end

  test "user can update their team details" do
    # Go to team edit page
    get edit_account_team_path(@team)
    assert_response :success

    # Update team
    patch account_team_path(@team), params: {
      team: {
        name: "Updated Team Name"
      }
    }

    @team.reload
    assert_equal "Updated Team Name", @team.name

    follow_redirect!
    assert_response :success
    assert_match "Updated Team Name", response.body
  end

  test "team automatically gets primary space on creation" do
    # Create a new team
    post account_teams_path, params: {
      team: {
        name: "Team with Auto Space"
      }
    }

    team = Team.last

    # Should have a primary space
    assert_not_nil team.primary_space
    assert_equal "Team with Auto Space's Space", team.primary_space.name
    assert_equal team, team.primary_space.team
  end

  test "user can create additional spaces for their team" do
    # Navigate to spaces page
    get account_team_spaces_path(@team)
    assert_response :success

    # Create new space
    assert_difference "Space.count", 1 do
      post account_team_spaces_path(@team), params: {
        space: {
          name: "Secondary Space",
          slug: "secondary-space",
          description: "An additional space for special content"
        }
      }
    end

    space = Space.last
    assert_equal "Secondary Space", space.name
    assert_equal "secondary-space", space.slug
    assert_equal @team, space.team

    follow_redirect!
    assert_response :success
  end

  test "user can update space details" do
    space = @team.primary_space

    # Go to space edit page
    get edit_account_space_path(space)
    assert_response :success

    # Update space
    patch account_space_path(space), params: {
      space: {
        name: "Updated Space Name",
        description: "New description"
      }
    }

    space.reload
    assert_equal "Updated Space Name", space.name
    assert_equal "New description", space.description.to_plain_text

    follow_redirect!
    assert_response :success
  end

  test "space slug must be unique within team" do
    # Create first space with slug
    post account_team_spaces_path(@team), params: {
      space: {
        name: "First Space",
        slug: "unique-slug"
      }
    }
    assert_response :redirect

    # Try to create second space with same slug
    assert_no_difference "Space.count" do
      post account_team_spaces_path(@team), params: {
        space: {
          name: "Second Space",
          slug: "unique-slug"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "user can list all spaces in their team" do
    # Create multiple spaces
    space1 = create(:space, team: @team, name: "Space One")
    space2 = create(:space, team: @team, name: "Space Two")
    space3 = create(:space, team: @team, name: "Space Three")

    # List spaces
    get account_team_spaces_path(@team)
    assert_response :success

    # All spaces should be visible (primary space should exist)
    assert @team.primary_space.present?, "Team should have a primary space"
    # Handle HTML encoding of apostrophes in space names
    primary_space_html = @team.primary_space.name.gsub("'", "&#39;")
    assert_includes response.body, primary_space_html
    assert_match space1.name, response.body
    assert_match space2.name, response.body
    assert_match space3.name, response.body
  end

  test "user cannot access spaces from other teams" do
    # Create another team with a space
    other_team = create(:team, name: "Other Team")
    other_space = create(:space, team: other_team, name: "Private Space")

    # Try to access the other team's space - should be denied (either 404 or redirect)
    get account_space_path(other_space)
    assert_includes [302, 404], response.status, "Should deny access with either redirect or not found"

    # Try to edit the other team's space - should be denied (either 404 or redirect)
    get edit_account_space_path(other_space)
    assert_includes [302, 404], response.status, "Should deny access with either redirect or not found"

    # Try to update the other team's space - should be denied (either 404 or redirect)
    patch account_space_path(other_space), params: {
      space: {
        name: "Hacked Name"
      }
    }
    assert_includes [302, 404], response.status, "Should deny access with either redirect or not found"

    # Verify space wasn't changed
    other_space.reload
    assert_equal "Private Space", other_space.name
  end

  test "team deletion cascades to spaces" do
    # Create team with spaces
    team = create(:team, name: "Deletable Team")
    @user.teams << team
    space1 = create(:space, team: team)
    space2 = create(:space, team: team)

    # Team now has 3 spaces: 1 primary (auto-created) + 2 created above
    initial_space_count = team.spaces.count
    assert_equal 3, initial_space_count, "Team should have 3 spaces (1 primary + 2 additional)"

    # Delete the team - all spaces should be deleted
    assert_difference "Team.count", -1 do
      assert_difference "Space.count", -initial_space_count do
        delete account_team_path(team)
      end
    end

    # Spaces should be gone
    assert_nil Space.find_by(id: space1.id)
    assert_nil Space.find_by(id: space2.id)
  end

  test "user can switch between teams" do
    # Create additional team
    team2 = create(:team, name: "Second Team")
    @user.teams << team2

    # Access first team
    get account_team_path(@team)
    assert_response :success
    assert_match @team.name, response.body

    # Switch to second team
    get account_team_path(team2)
    assert_response :success
    assert_match team2.name, response.body
  end
end
