require "test_helper"

class Account::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:onboarded_user)
    sign_in @user
    @team = @user.current_team
    @space = create(:space, team: @team)
  end

  test "should require authentication" do
    sign_out @user
    get account_analytics_index_url
    assert_redirected_to new_user_session_path
  end

  test "should redirect if no current team" do
    @user.update(current_team: nil)
    get account_analytics_index_url
    assert_redirected_to account_teams_path
    assert_equal "You need to select a team first.", flash[:alert]
  end

  test "should get index with default 30 day range" do
    get account_analytics_index_url
    assert_response :success
    assert_equal 30, assigns(:date_range)
    assert_equal @team, assigns(:team)
  end

  test "should respect custom date range parameter" do
    get account_analytics_index_url(days: 7)
    assert_response :success
    assert_equal 7, assigns(:date_range)
  end

  test "should handle 90 day date range" do
    get account_analytics_index_url(days: 90)
    assert_response :success
    assert_equal 90, assigns(:date_range)
  end

  test "should calculate correct date range" do
    get account_analytics_index_url(days: 7)
    assert_equal 7.days.ago.to_date, assigns(:start_date)
    assert_equal Date.current, assigns(:end_date)
  end

  test "should load team snapshots" do
    # Create test data
    create(:analytics_daily_snapshot,
      team: @team,
      space: nil,
      date: Date.current,
      total_revenue_cents: 5000)

    get account_analytics_index_url
    assert_response :success
    assert_not_nil assigns(:team_snapshots)
    assert assigns(:team_snapshots).any?
  end

  test "should load space snapshots" do
    # Create test data
    create(:analytics_daily_snapshot,
      team: @team,
      space: @space,
      date: Date.current,
      total_revenue_cents: 3000)

    get account_analytics_index_url
    assert_response :success
    assert_not_nil assigns(:space_snapshots)
  end

  test "should calculate summary metrics" do
    # Create test data
    create(:analytics_daily_snapshot,
      team: @team,
      space: nil,
      date: Date.current,
      total_revenue_cents: 5000,
      purchases_count: 3,
      active_passes_count: 10,
      stream_views: 100,
      chat_messages: 50)

    get account_analytics_index_url
    assert_response :success

    assert_equal 5000, assigns(:total_revenue)
    assert_equal 3, assigns(:total_purchases)
    assert_equal 10, assigns(:total_active_passes)
    assert_equal 100, assigns(:total_stream_views)
    assert_equal 50, assigns(:total_chat_messages)
  end

  test "should prepare chart data" do
    # Create test data
    create(:analytics_daily_snapshot,
      team: @team,
      space: nil,
      date: Date.current,
      total_revenue_cents: 5000,
      purchases_count: 3,
      active_passes_count: 1,
      stream_views: 100,
      chat_messages: 50)

    get account_analytics_index_url
    assert_response :success

    assert_not_nil assigns(:revenue_chart_data)
    assert_not_nil assigns(:purchases_chart_data)
    assert_not_nil assigns(:engagement_chart_data)
    assert_not_nil assigns(:space_performance_data)
  end

  test "should load recent snapshots" do
    # Create test data
    snapshot = create(:analytics_daily_snapshot,
      team: @team,
      space: nil,
      date: Date.current,
      total_revenue_cents: 5000)

    get account_analytics_index_url
    assert_response :success

    assert_not_nil assigns(:recent_snapshots)
    assert_includes assigns(:recent_snapshots), snapshot
  end

  test "should set has_data flag correctly when data exists" do
    create(:analytics_daily_snapshot,
      team: @team,
      space: nil,
      date: Date.current)

    get account_analytics_index_url
    assert_response :success
    assert assigns(:has_data)
  end

  test "should set has_data flag correctly when no data exists" do
    get account_analytics_index_url
    assert_response :success
    assert_not assigns(:has_data)
  end

  test "should trigger analytics job when no recent data" do
    assert_enqueued_with(job: DailyAnalyticsJob, args: [Date.current]) do
      get account_analytics_index_url
    end

    assert_equal "Analytics are being generated. Refresh the page in a few moments to see your data.",
      flash.now[:info]
  end

  test "should not trigger analytics job when recent data exists" do
    create(:analytics_daily_snapshot,
      team: @team,
      space: nil,
      date: Date.current)

    assert_no_enqueued_jobs do
      get account_analytics_index_url
    end
  end

  test "should render analytics dashboard view" do
    get account_analytics_index_url
    assert_response :success
    assert_select "h1", "Analytics Dashboard"
    assert_select ".bg-white.rounded-lg.shadow", minimum: 1 # Summary cards
  end

  test "should show no data state when appropriate" do
    get account_analytics_index_url
    assert_response :success
    assert_select "h3", "No analytics data yet"
    assert_select "p", text: /Analytics data will appear here/
  end

  test "should display date range buttons" do
    get account_analytics_index_url
    assert_response :success
    assert_select "a[href*='days=7']", "7 Days"
    assert_select "a[href*='days=30']", "30 Days"
    assert_select "a[href*='days=90']", "90 Days"
  end

  test "should highlight active date range button" do
    get account_analytics_index_url(days: 7)
    assert_response :success
    assert_select "a[href*='days=7'].bg-blue-100", "7 Days"
  end
end
