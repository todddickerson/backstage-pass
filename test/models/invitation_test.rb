require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @team_owner = create(:onboarded_user)
    @invited_user = create(:user) # User without a team membership yet
    @membership = Membership.new(team: @team_owner.current_team)
    @invitation = Invitation.create(team: @team_owner.current_team, email: @invited_user.email, from_membership: @team_owner.memberships.first, membership: @membership)
  end

  test "must set uuid" do
    assert @invitation.uuid.present?
  end

  test "accept_for must set team" do
    @invitation.accept_for(@invited_user)
    assert_equal @team_owner.current_team, @invitation.team
  end

  test "accept_for must destroy invitation" do
    @invitation.accept_for(@invited_user)
    assert @invitation.destroyed?
  end

  test "must be valid" do
    assert @invitation.valid?
  end
end
