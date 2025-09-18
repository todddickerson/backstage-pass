class Analytics::DailySnapshot < ApplicationRecord
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :team
  belongs_to :space, optional: true
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  # 🚅 add has_one associations above.

  scope :for_space, ->(space) { where(space: space) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :recent, ->(days = 30) { where(date: days.days.ago..Date.current) }
  scope :by_date, -> { order(:date) }
  # 🚅 add scopes above.

  validates :date, presence: true, uniqueness: {scope: [:team_id, :space_id]}
  validates :space, scope: true
  validates :total_revenue_cents, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :purchases_count, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :active_passes_count, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :stream_views, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :chat_messages, presence: true, numericality: {greater_than_or_equal_to: 0}
  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  def valid_spaces
    team.spaces
  end

  # Helper methods for analytics calculations
  def revenue_display
    "$#{(total_revenue_cents / 100.0).round(2)}"
  end

  def average_revenue_per_purchase
    return 0 if purchases_count.zero?
    total_revenue_cents / purchases_count / 100.0
  end

  def engagement_rate
    return 0 if stream_views.zero?
    (chat_messages.to_f / stream_views * 100).round(2)
  end

  # 🚅 add methods above.
end
