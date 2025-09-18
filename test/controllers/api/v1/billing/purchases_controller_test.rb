require "controllers/api/v1/test"

class Api::V1::Billing::PurchasesControllerTest < Api::Test
  setup do
    # See `test/controllers/api/test.rb` for common set up for API tests.

    @purchase = build(:billing_purchase, team: @team)
    @other_purchases = create_list(:billing_purchase, 3)

    @another_purchase = create(:billing_purchase, team: @team)

    # 🚅 super scaffolding will insert file-related logic above this line.
    @purchase.save
    @another_purchase.save

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
  def assert_proper_object_serialization(purchase_data)
    # Fetch the purchase in question and prepare to compare it's attributes.
    purchase = Billing::Purchase.find(purchase_data["id"])

    assert_equal_or_nil purchase_data["user_id"], purchase.user_id
    assert_equal_or_nil purchase_data["access_pass_id"], purchase.access_pass_id
    assert_equal_or_nil purchase_data["amount_cents"], purchase.amount_cents
    assert_equal_or_nil purchase_data["stripe_charge_id"], purchase.stripe_charge_id
    assert_equal_or_nil purchase_data["stripe_payment_intent_id"], purchase.stripe_payment_intent_id
    assert_equal_or_nil purchase_data["status"], purchase.status
    # 🚅 super scaffolding will insert new fields above this line.

    assert_equal purchase_data["team_id"], purchase.team_id
  end

  test "index" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/teams/#{@team.id}/billing/purchases", params: {access_token: access_token}
    assert_response :success

    # Make sure it's returning our resources.
    purchase_ids_returned = response.parsed_body.map { |purchase| purchase["id"] }
    assert_includes(purchase_ids_returned, @purchase.id)

    # But not returning other people's resources.
    assert_not_includes(purchase_ids_returned, @other_purchases[0].id)

    # And that the object structure is correct.
    assert_proper_object_serialization response.parsed_body.first
  end

  test "show" do
    # Fetch and ensure nothing is seriously broken.
    get "/api/v1/billing/purchases/#{@purchase.id}", params: {access_token: access_token}
    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    get "/api/v1/billing/purchases/#{@purchase.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "create" do
    # Use the serializer to generate a payload, but strip some attributes out.
    params = {access_token: access_token}
    params[:billing_purchase] = {
      user_id: @user.id,
      access_pass_id: nil,
      amount_cents: 100,
      stripe_charge_id: "ch_test_123",
      stripe_payment_intent_id: "pi_test_123",
      status: "completed"
    }

    post "/api/v1/teams/#{@team.id}/billing/purchases", params: params
    assert_response :success

    # # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # Also ensure we can't do that same action as another user.
    post "/api/v1/teams/#{@team.id}/billing/purchases",
      params: params.merge({access_token: another_access_token})
    assert_response :not_found
  end

  test "update" do
    # Post an attribute update ensure nothing is seriously broken.
    put "/api/v1/billing/purchases/#{@purchase.id}", params: {
      access_token: access_token,
      billing_purchase: {
        stripe_charge_id: "Alternative String Value",
        stripe_payment_intent_id: "Alternative String Value",
        # 🚅 super scaffolding will also insert new fields above this line.
      }
    }

    assert_response :success

    # Ensure all the required data is returned properly.
    assert_proper_object_serialization response.parsed_body

    # But we have to manually assert the value was properly updated.
    @purchase.reload
    assert_equal @purchase.stripe_charge_id, "Alternative String Value"
    assert_equal @purchase.stripe_payment_intent_id, "Alternative String Value"
    # 🚅 super scaffolding will additionally insert new fields above this line.

    # Also ensure we can't do that same action as another user.
    put "/api/v1/billing/purchases/#{@purchase.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end

  test "destroy" do
    # Delete and ensure it actually went away.
    assert_difference("Billing::Purchase.count", -1) do
      delete "/api/v1/billing/purchases/#{@purchase.id}", params: {access_token: access_token}
      assert_response :success
    end

    # Also ensure we can't do that same action as another user.
    delete "/api/v1/billing/purchases/#{@another_purchase.id}", params: {access_token: another_access_token}
    assert_response :not_found
  end
end
