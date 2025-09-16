require "controllers/api/v1/test"

class Api::V1::AccessPasses::WaitlistEntriesControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @access_pass = create(:access_pass, team: @team)
    @waitlist_entry = build(:access_passes_waitlist_entry, access_pass: @access_pass)
    @other_waitlist_entries = create_list(:access_passes_waitlist_entry, 3)

    @another_waitlist_entry = create(:access_passes_waitlist_entry, access_pass: @access_pass)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @waitlist_entry.save
    @another_waitlist_entry.save

    @original_hide_things = ENV["HIDE_THINGS"]
    ENV["HIDE_THINGS"] = "false"
    Rails.application.reload_routes!
  end

  teardown do
    ENV["HIDE_THINGS"] = @original_hide_things
    Rails.application.reload_routes!
  end

  # This assertion is written in such a way that new attributes won't cause the tests to start failing, but removing
  # data we were previously providing to users _will_ break the test suite.
  def assert_proper_object_serialization(waitlist_entry_data)
    # Fetch the waitlist_entry in question and prepare to compare it's attributes.
    waitlist_entry = AccessPasses::WaitlistEntry.find(waitlist_entry_data["id"])

    assert_equal_or_nil waitlist_entry_data['email'], waitlist_entry.email
    assert_equal_or_nil waitlist_entry_data['first_name'], waitlist_entry.first_name
    assert_equal_or_nil waitlist_entry_data['last_name'], waitlist_entry.last_name
    assert_equal_or_nil waitlist_entry_data['answers'], waitlist_entry.answers
    assert_equal_or_nil waitlist_entry_data['status'], waitlist_entry.status
    assert_equal_or_nil waitlist_entry_data['notes'], waitlist_entry.notes
    assert_equal_or_nil DateTime.parse(waitlist_entry_data['approved_at']), waitlist_entry.approved_at
    assert_equal_or_nil DateTime.parse(waitlist_entry_data['rejected_at']), waitlist_entry.rejected_at
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal waitlist_entry_data["access_pass_id"], waitlist_entry.access_pass_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/access_passes/#{@access_pass.id}/waitlist_entries", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    waitlist_entry_ids_returned = response.parsed_body.map { |waitlist_entry| waitlist_entry["id"] }
    assert_includes(waitlist_entry_ids_returned, @waitlist_entry.id)

    # But not returning other people's resources.
    assert_not_includes(waitlist_entry_ids_returned, @other_waitlist_entries[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/access_passes/waitlist_entries/#{@waitlist_entry.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/access_passes/waitlist_entries/#{@waitlist_entry.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    waitlist_entry_data = JSON.parse(build(:access_passes_waitlist_entry, access_pass: nil).api_attributes.to_json)
    waitlist_entry_data.except!("id", "access_pass_id", "created_at", "updated_at")
    params[:access_passes_waitlist_entry] = waitlist_entry_data

    post "/api/v1/access_passes/#{@access_pass.id}/waitlist_entries", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/access_passes/#{@access_pass.id}/waitlist_entries",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/access_passes/waitlist_entries/#{@waitlist_entry.id}", params: {
      access_token: access_token,
      access_passes_waitlist_entry: {
        email: 'another.email@test.com',
        first_name: 'Alternative String Value',
        last_name: 'Alternative String Value',
        answers: 'Alternative String Value',
        notes: 'Alternative String Value',
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @waitlist_entry.reload
    assert_equal @waitlist_entry.email, 'another.email@test.com'
    assert_equal @waitlist_entry.first_name, 'Alternative String Value'
    assert_equal @waitlist_entry.last_name, 'Alternative String Value'
    assert_equal @waitlist_entry.answers, 'Alternative String Value'
    assert_equal @waitlist_entry.notes, 'Alternative String Value'
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/access_passes/waitlist_entries/#{@waitlist_entry.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("AccessPasses::WaitlistEntry.count", -1) do
      delete "/api/v1/access_passes/waitlist_entries/#{@waitlist_entry.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/access_passes/waitlist_entries/#{@another_waitlist_entry.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
