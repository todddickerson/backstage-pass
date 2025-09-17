require "test_helper"

class TeamSpaceManagementFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @user = create(:onboarded_user)
    @team = @user.current_team
    sign_in @user
  end
  
  test "user can create a new team" do
    # Navigate to teams page
    get account_teams_path
    assert_response :success
    
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
    
    # User should be a member of the new team
    assert @user.teams.include?(team)
    
    # User should have admin role in the new team
    membership = @user.memberships.find_by(team: team)
    assert_not_nil membership
    assert_includes membership.user_roles, "admin"
    
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
    assert_equal "Main Space", team.primary_space.name
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
    get edit_account_team_space_path(@team, space)
    assert_response :success
    
    # Update space
    patch account_team_space_path(@team, space), params: {
      space: {
        name: "Updated Space Name",
        description: "New description"
      }
    }
    
    space.reload
    assert_equal "Updated Space Name", space.name
    assert_equal "New description", space.description
    
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
    
    # All spaces should be visible
    assert_match @team.primary_space.name, response.body
    assert_match space1.name, response.body
    assert_match space2.name, response.body
    assert_match space3.name, response.body
  end
  
  test "user cannot access spaces from other teams" do
    # Create another team with a space
    other_team = create(:team, name: "Other Team")
    other_space = create(:space, team: other_team, name: "Private Space")
    
    # Try to access the other team's space
    get account_team_space_path(other_team, other_space)
    assert_response :forbidden
    
    # Try to edit the other team's space
    get edit_account_team_space_path(other_team, other_space)
    assert_response :forbidden
    
    # Try to update the other team's space
    patch account_team_space_path(other_team, other_space), params: {
      space: {
        name: "Hacked Name"
      }
    }
    assert_response :forbidden
    
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
    
    # Delete the team
    assert_difference ["Team.count", "Space.count"], [-1, -2] do
      delete account_team_path(team)
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