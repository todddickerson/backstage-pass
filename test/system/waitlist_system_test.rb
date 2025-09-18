require "application_system_test_case"

class WaitlistSystemTest < ApplicationSystemTestCase
  setup do
    @creator = create(:onboarded_user, first_name: "Creator", last_name: "Test")
    @space = @creator.current_team.primary_space
    @access_pass = @space.access_passes.create!(
      name: "VIP Membership",
      description: "Premium access to all content",
      pricing_type: "one_time",
      price_cents: 2999,
      published: true,
      slug: "vip-membership"
    )

    # Add custom questions to the access pass
    @access_pass.update!(
      custom_questions: [
        {
          "id" => SecureRandom.uuid,
          "text" => "Why do you want to join this community?",
          "type" => "textarea",
          "required" => true,
          "options" => []
        },
        {
          "id" => SecureRandom.uuid,
          "text" => "What is your experience level?",
          "type" => "select",
          "required" => true,
          "options" => ["Beginner", "Intermediate", "Advanced"]
        }
      ]
    )
  end

  device_test "public user can apply to waitlist without custom questions" do
    # Create an access pass without custom questions
    simple_pass = @space.access_passes.create!(
      name: "Simple Pass",
      description: "Basic access",
      pricing_type: "one_time",
      price_cents: 999,
      published: true,
      slug: "simple-pass"
    )

    # Visit the waitlist application page
    visit new_waitlist_entry_path(@space.slug, simple_pass.slug)

    # Should see the waitlist form
    assert_text("Join the Waitlist")
    assert_text(simple_pass.name)

    # Fill out the basic form
    fill_in "First Name", with: "Simple"
    fill_in "Last Name", with: "User"
    fill_in "Email", with: "simple@example.com"

    # Submit the application
    click_on "Join Waitlist"

    # Should be redirected to success page
    assert_text("You're on the list!")

    # Verify the waitlist entry was created
    waitlist_entry = AccessPasses::WaitlistEntry.find_by(email: "simple@example.com")
    assert_not_nil waitlist_entry
    assert_equal "pending", waitlist_entry.status
    assert_equal "Simple", waitlist_entry.first_name
    assert_equal "User", waitlist_entry.last_name
  end

  device_test "public user can apply to waitlist with custom questions" do
    # Visit the waitlist application page
    visit new_waitlist_entry_path(@space.slug, @access_pass.slug)

    # Should see the waitlist form
    assert_text("Join the Waitlist")
    assert_text(@access_pass.name)
    assert_text("Why do you want to join this community?")
    assert_text("What is your experience level?")

    # Fill out the application form
    fill_in "First Name", with: "Jane"
    fill_in "Last Name", with: "Doe"
    fill_in "Email", with: "applicant@example.com"

    # Custom questions use dynamic IDs, so we'll find them by their labels
    # For the textarea question
    within(".question-container", text: "Why do you want to join this community?") do
      find("textarea").set("I'm passionate about this topic and want to learn from experts.")
    end

    # For the select question
    within(".question-container", text: "What is your experience level?") do
      find("select").select("Intermediate")
    end

    # Submit the application
    click_on "Join Waitlist"

    # Should be redirected to success page
    assert_text("You're on the list!")

    # Verify the waitlist entry was created
    waitlist_entry = AccessPasses::WaitlistEntry.find_by(email: "applicant@example.com")
    assert_not_nil waitlist_entry
    assert_equal "pending", waitlist_entry.status
    assert_equal "Jane", waitlist_entry.first_name
    assert_equal "Doe", waitlist_entry.last_name
  end

  device_test "creator can view and manage waitlist entries" do
    # Create a waitlist entry first
    @access_pass.waitlist_entries.create!(
      email: "test@example.com",
      first_name: "Test",
      last_name: "User",
      status: "pending",
      answers: {
        "Why do you want to join this community?" => "Very interested in learning",
        "What is your experience level?" => "Beginner"
      }
    )

    # Login as creator
    login_as(@creator, scope: :user)

    # Navigate to waitlist entries via space access passes
    visit account_team_space_access_passes_path(@creator.current_team, @space)
    click_on @access_pass.name
    click_on "Waitlist Entries"

    # Should see the waitlist entry
    assert_text("test@example.com")
    assert_text("Test")
    assert_text("User")

    # Click to view details
    click_on "test@example.com"

    # Should see full details including answers
    assert_text("Test User")
    assert_text("test@example.com")
    assert_text("Very interested in learning")
    assert_text("Beginner")
    assert_text("Pending")

    # Should see approve/reject buttons
    assert_button("Approve")
    assert_button("Reject")
  end

  device_test "creator can approve waitlist application" do
    # Create a waitlist entry
    waitlist_entry = @access_pass.waitlist_entries.create!(
      email: "approve@example.com",
      first_name: "Approve",
      last_name: "Test",
      status: "pending",
      answers: {"Question" => "Answer"}
    )

    # Login as creator
    login_as(@creator, scope: :user)

    # Navigate to the waitlist entry
    visit account_access_passes_waitlist_entry_path(waitlist_entry)

    # Approve the application (handle confirmation dialog)
    accept_confirm do
      click_on "Approve"
    end

    # Should see success message
    assert_text("Application has been approved and email sent.")

    # Should see updated status
    assert_text("Approved")

    # Verify the database was updated
    waitlist_entry.reload
    assert_equal "approved", waitlist_entry.status
    assert_not_nil waitlist_entry.approved_at

    # Should not see approve/reject buttons anymore
    assert_no_button("Approve")
    assert_no_button("Reject")
  end

  device_test "creator can reject waitlist application" do
    # Create a waitlist entry
    waitlist_entry = @access_pass.waitlist_entries.create!(
      email: "reject@example.com",
      first_name: "Reject",
      last_name: "Test",
      status: "pending",
      answers: {"Question" => "Answer"}
    )

    # Login as creator
    login_as(@creator, scope: :user)

    # Navigate to the waitlist entry
    visit account_access_passes_waitlist_entry_path(waitlist_entry)

    # Reject the application (handle confirmation dialog)
    accept_confirm do
      click_on "Reject"
    end

    # Should see success message
    assert_text("Application has been rejected.")

    # Should see updated status
    assert_text("Rejected")

    # Verify the database was updated
    waitlist_entry.reload
    assert_equal "rejected", waitlist_entry.status
    assert_not_nil waitlist_entry.rejected_at

    # Should not see approve/reject buttons anymore
    assert_no_button("Approve")
    assert_no_button("Reject")
  end

  device_test "creator can add notes when approving applications" do
    # Create a waitlist entry
    waitlist_entry = @access_pass.waitlist_entries.create!(
      email: "notes@example.com",
      first_name: "Notes",
      last_name: "Test",
      status: "pending",
      answers: {"Question" => "Answer"}
    )

    # Login as creator
    login_as(@creator, scope: :user)

    # Navigate to edit the waitlist entry to add notes
    visit edit_account_access_passes_waitlist_entry_path(waitlist_entry)

    # Add notes
    fill_in "Notes", with: "Excited to welcome this member to our community!"
    click_on "Update Waitlist Entry"

    # Now approve with the notes (handle confirmation dialog)
    accept_confirm do
      click_on "Approve"
    end

    # Verify the notes were saved and application approved
    waitlist_entry.reload
    assert_equal "Excited to welcome this member to our community!", waitlist_entry.notes
    assert_equal "approved", waitlist_entry.status
  end

  device_test "complete waitlist workflow: application to approval" do
    # Step 1: Public user applies to waitlist
    visit new_waitlist_entry_path(@space.slug, @access_pass.slug)

    fill_in "First Name", with: "Workflow"
    fill_in "Last Name", with: "Test"
    fill_in "Email", with: "workflow@example.com"

    # Custom questions use dynamic IDs, so we'll find them by their labels
    within(".question-container", text: "Why do you want to join this community?") do
      find("textarea").set("Complete workflow test")
    end

    within(".question-container", text: "What is your experience level?") do
      find("select").select("Advanced")
    end

    click_on "Join Waitlist"
    assert_text("You're on the list!")

    # Step 2: Creator logs in and reviews application
    login_as(@creator, scope: :user)
    visit account_team_space_access_passes_path(@creator.current_team, @space)
    click_on @access_pass.name
    click_on "Waitlist Entries"

    # Should see the new application
    assert_text("workflow@example.com")
    click_on "workflow@example.com"

    # Step 3: Creator reviews details and approves
    assert_text("Complete workflow test")
    assert_text("Advanced")
    assert_text("Pending")

    # Step 4: Approve the application (handle confirmation dialog)
    accept_confirm do
      click_on "Approve"
    end

    # Step 5: Verify final state
    assert_text("Approved")
    waitlist_entry = AccessPasses::WaitlistEntry.find_by(email: "workflow@example.com")
    assert_equal "approved", waitlist_entry.status
    assert_not_nil waitlist_entry.approved_at

    puts "✅ Complete waitlist workflow validated!"
  end

  device_test "public user cannot access non-existent access pass waitlist" do
    # Try to visit waitlist for non-existent access pass
    visit new_waitlist_entry_path(@space.slug, "non-existent-pass")

    # Should see error page
    assert_text("ActiveRecord::RecordNotFound") || assert_text("Couldn't find AccessPass")
  end

  device_test "waitlist form validation works correctly" do
    visit new_waitlist_entry_path(@space.slug, @access_pass.slug)

    # Try to submit without required fields
    click_on "Join Waitlist"

    # Should see validation errors
    assert_text("can't be blank") || assert_text("is required")

    # Fill only email and try again
    fill_in "Email", with: "partial@example.com"
    click_on "Join Waitlist"

    # Should still see validation errors for missing fields
    assert_text("can't be blank") || assert_text("is required")
  end
end
