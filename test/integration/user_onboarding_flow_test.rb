require "test_helper"

class UserOnboardingFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "complete user registration and onboarding flow" do
    # Start from the root page
    get root_path
    assert_response :redirect
    follow_redirect!
    assert_match(/sign in/i, response.body)

    # Navigate to sign up
    get new_user_registration_path
    assert_response :success
    assert_select "form[action=?][method=?]", user_registration_path, "post"

    # Register a new user
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "SecureP@ssw0rd2025!",
          password_confirmation: "SecureP@ssw0rd2025!",
          first_name: "New",
          last_name: "User",
          time_zone: "America/New_York"
        }
      }
    end

    user = User.last
    assert_equal "newuser@example.com", user.email
    assert_equal "New", user.first_name
    assert_equal "User", user.last_name

    # User should be signed in after registration
    follow_redirect!
    assert_response :success

    # User should have a default team created
    assert_not_nil user.current_team
    assert_equal 1, user.teams.count

    # Verify user can access their dashboard
    get account_dashboard_path
    assert_response :success
  end

  test "user cannot register with invalid data" do
    # Try to register with missing required fields
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          email: "",
          password: "short",
          password_confirmation: "different",
          first_name: "",
          last_name: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error", minimum: 1
  end

  test "existing user can sign in and access account" do
    user = create(:onboarded_user, email: "existing@example.com", password: "SecureP@ssw0rd2025!")

    # Sign in
    post user_session_path, params: {
      user: {
        email: "existing@example.com",
        password: "SecureP@ssw0rd2025!"
      }
    }
    assert_response :redirect

    # Follow redirects until we reach a final page
    follow_redirect!
    # May redirect from teams index to first team
    if response.redirect?
      follow_redirect!
    end
    assert_response :success

    # Access protected pages
    get account_dashboard_path
    assert_response :success

    get account_team_path(user.current_team)
    assert_response :success
  end

  test "user can update their profile after onboarding" do
    user = create(:onboarded_user)
    sign_in user

    # Go to edit profile
    get edit_user_registration_path
    assert_response :success

    # Update profile
    patch user_registration_path, params: {
      user: {
        first_name: "Updated",
        last_name: "Name",
        time_zone: "Europe/London",
        current_password: user.password
      }
    }

    follow_redirect!
    assert_response :success

    user.reload
    assert_equal "Updated", user.first_name
    assert_equal "Name", user.last_name
    assert_equal "Europe/London", user.time_zone
  end

  test "user can sign out successfully" do
    user = create(:onboarded_user)
    sign_in user

    # Verify signed in
    get account_dashboard_path
    assert_response :success

    # Sign out
    delete destroy_user_session_path
    follow_redirect!

    # Cannot access protected pages
    get account_dashboard_path
    assert_response :redirect
    follow_redirect!
    assert_match(/sign in/i, response.body)
  end

  test "password reset flow works correctly" do
    create(:onboarded_user, email: "forgot@example.com")

    # Request password reset
    get new_user_password_path
    assert_response :success

    post user_password_path, params: {
      user: {
        email: "forgot@example.com"
      }
    }

    follow_redirect!
    assert_response :success
    assert_match(/reset password instructions/i, response.body)

    # Email should be sent
    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    assert_equal ["forgot@example.com"], email.to
    assert_match(/reset password/i, email.subject)
  end
end
