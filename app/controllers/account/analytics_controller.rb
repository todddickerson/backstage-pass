class Account::AnalyticsController < Account::ApplicationController
  before_action :authenticate_user!

  def index
    # Ensure user has access to analytics for their current team
    @team = current_user.current_team
    redirect_to account_teams_path, alert: "You need to select a team first." unless @team

    # Set date range (default to last 30 days)
    @date_range = params[:days]&.to_i || 30
    @start_date = @date_range.days.ago.to_date
    @end_date = Date.current

    # Get team-level analytics (space_id is nil for team aggregates)
    @team_snapshots = Analytics::DailySnapshot
      .where(team: @team, space: nil)
      .for_date_range(@start_date, @end_date)
      .by_date

    # Get space-level analytics
    @space_snapshots = Analytics::DailySnapshot
      .where(team: @team)
      .where.not(space: nil)
      .for_date_range(@start_date, @end_date)
      .includes(:space)
      .by_date

    # Calculate summary metrics
    @total_revenue = @team_snapshots.sum(:total_revenue_cents)
    @total_purchases = @team_snapshots.sum(:purchases_count)
    @total_active_passes = @team_snapshots.maximum(:active_passes_count) || 0
    @total_stream_views = @team_snapshots.sum(:stream_views)
    @total_chat_messages = @team_snapshots.sum(:chat_messages)

    # Prepare chart data
    @revenue_chart_data = prepare_revenue_chart_data
    @purchases_chart_data = prepare_purchases_chart_data
    @engagement_chart_data = prepare_engagement_chart_data
    @space_performance_data = prepare_space_performance_data

    # Recent activity
    @recent_snapshots = @team_snapshots.limit(7).reverse

    # Check if we have any data
    @has_data = @team_snapshots.any?

    # Run analytics job if no recent data exists
    if !@has_data && @team_snapshots.where(date: Date.current).empty?
      DailyAnalyticsJob.perform_later(Date.current)
      flash.now[:info] = "Analytics are being generated. Refresh the page in a few moments to see your data."
    end
  end

  private

  def prepare_revenue_chart_data
    @team_snapshots.pluck(:date, :total_revenue_cents).map do |date, revenue_cents|
      [date.strftime("%m/%d"), revenue_cents / 100.0]
    end
  end

  def prepare_purchases_chart_data
    @team_snapshots.pluck(:date, :purchases_count)
  end

  def prepare_engagement_chart_data
    @team_snapshots.pluck(:date, :stream_views, :chat_messages).map do |date, views, messages|
      engagement_rate = (views > 0) ? (messages.to_f / views * 100).round(2) : 0
      [date.strftime("%m/%d"), engagement_rate]
    end
  end

  def prepare_space_performance_data
    # Group by space and sum metrics (remove ordering first to avoid SQL error)
    space_data = @space_snapshots.reorder(nil).group(:space).sum(:total_revenue_cents)
    space_data.map do |space, revenue_cents|
      [space.name, revenue_cents / 100.0]
    end
  end
end
