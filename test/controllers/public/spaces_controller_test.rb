require "test_helper"

class Public::SpacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = FactoryBot.create(:onboarded_user)
    @team = @user.current_team

    @published_space = FactoryBot.create(:space,
      team: @team,
      published: true,
      name: "Test Space",
      slug: "test-space",
      description: "A test space for marketplace")

    @unpublished_space = FactoryBot.create(:space,
      team: @team,
      published: false,
      name: "Unpublished Space",
      slug: "unpublished-space")

    @access_pass = FactoryBot.create(:access_pass,
      space: @published_space,
      team: @team,
      published: true,
      name: "Basic Access",
      price_cents: 1000,
      pricing_type: "monthly")
  end

  test "should get index" do
    get explore_spaces_url
    assert_response :success
    assert_select "h1", text: /Discover Amazing Creators/
  end

  test "should only show published spaces in index" do
    get explore_spaces_url
    assert_response :success
    assert_match @published_space.name, response.body
    assert_no_match @unpublished_space.name, response.body
  end

  test "should filter spaces by search term" do
    get explore_spaces_url, params: {search: @published_space.name}
    assert_response :success
    assert_match @published_space.name, response.body
  end

  test "should sort spaces by newest" do
    get explore_spaces_url, params: {sort_by: "newest"}
    assert_response :success
  end

  test "should filter spaces by price range" do
    get explore_spaces_url, params: {min_price: 5, max_price: 15}
    assert_response :success
  end

  test "should show published space" do
    get public_space_url(@published_space.slug)
    assert_response :success
  end

  test "should not show unpublished space" do
    # Test by slug that should exist but be unpublished
    get public_space_url(@unpublished_space.slug)
    assert_response :not_found
  end

  test "should show access pass pricing in index" do
    get explore_spaces_url
    assert_response :success
    assert_match "Basic Access", response.body
    assert_match "$10", response.body
    assert_match "/mo", response.body
  end
end
