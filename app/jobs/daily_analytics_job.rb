class DailyAnalyticsJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    Rails.logger.info "Starting daily analytics collection for #{date}"

    Team.includes(:spaces).find_each do |team|
      Rails.logger.info "Processing analytics for team: #{team.name}"

      # Create team-level snapshot (aggregated across all spaces)
      create_team_snapshot(team, date)

      # Create space-level snapshots
      team.spaces.each do |space|
        create_space_snapshot(team, space, date)
      end
    end

    Rails.logger.info "Daily analytics collection completed for #{date}"
  end

  private

  def create_team_snapshot(team, date)
    # Aggregate data across all spaces in the team
    total_revenue = team.spaces.sum(:total_revenue_cents)
    total_purchases = team.spaces.sum(:purchases_count)
    total_active_passes = team.spaces.joins(:access_passes).sum(:access_grants_count)
    total_stream_views = team.spaces.joins(experiences: :streams).sum(:total_viewers)
    total_chat_messages = team.spaces.joins(experiences: :streams).sum(:chat_messages_count)

    # Create or update team snapshot (space_id is nil for team-level)
    snapshot = Analytics::DailySnapshot.find_or_initialize_by(
      team: team,
      space: nil,
      date: date
    )

    snapshot.assign_attributes(
      total_revenue_cents: total_revenue,
      purchases_count: total_purchases,
      active_passes_count: total_active_passes,
      stream_views: total_stream_views,
      chat_messages: total_chat_messages
    )

    if snapshot.save
      Rails.logger.info "Created team snapshot for #{team.name}: $#{total_revenue / 100.0}"
    else
      Rails.logger.error "Failed to save team snapshot: #{snapshot.errors.full_messages}"
    end
  end

  def create_space_snapshot(team, space, date)
    # Calculate space-specific metrics
    space_revenue = calculate_space_revenue(space, date)
    space_purchases = calculate_space_purchases(space, date)
    active_passes = space.access_passes.sum(:access_grants_count)
    stream_views = calculate_stream_views(space, date)
    chat_messages = calculate_chat_messages(space, date)

    # Create or update space snapshot
    snapshot = Analytics::DailySnapshot.find_or_initialize_by(
      team: team,
      space: space,
      date: date
    )

    snapshot.assign_attributes(
      total_revenue_cents: space_revenue,
      purchases_count: space_purchases,
      active_passes_count: active_passes,
      stream_views: stream_views,
      chat_messages: chat_messages
    )

    if snapshot.save
      Rails.logger.info "Created space snapshot for #{space.name}: $#{space_revenue / 100.0}"
    else
      Rails.logger.error "Failed to save space snapshot: #{snapshot.errors.full_messages}"
    end
  end

  def calculate_space_revenue(space, date)
    # Sum revenue from access grants for this space and its experiences
    # This would need to be adjusted based on your actual access grant structure
    space.access_grants.joins(:access_pass)
      .where(created_at: date.beginning_of_day..date.end_of_day)
      .sum("access_passes.price_cents")
  end

  def calculate_space_purchases(space, date)
    # Count purchases (access grants) for this space
    space.access_grants
      .where(created_at: date.beginning_of_day..date.end_of_day)
      .count
  end

  def calculate_stream_views(space, date)
    # This is a placeholder - you'd need to implement actual view tracking
    # For now, we'll use the counter cache totals
    space.experiences.joins(:streams).sum(:total_viewers)
  end

  def calculate_chat_messages(space, date)
    # This is a placeholder - you'd need to implement actual message tracking
    # For now, we'll use the counter cache totals
    space.experiences.joins(:streams).sum(:chat_messages_count)
  end
end
