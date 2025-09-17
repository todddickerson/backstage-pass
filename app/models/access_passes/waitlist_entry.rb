class AccessPasses::WaitlistEntry < ApplicationRecord
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :access_pass
  belongs_to :user, optional: true  # Optional because they might not have an account yet
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  has_one :team, through: :access_pass
  # 🚅 add has_one associations above.

  # Status scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :recent, -> { order(created_at: :desc) }
  # 🚅 add scopes above.

  validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :status, presence: true, inclusion: {in: %w[pending approved rejected]}
  # 🚅 add validations above.

  # Set default status
  after_initialize :set_default_status, if: :new_record?
  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # Status helper methods
  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def can_be_processed?
    pending?
  end

  # Parse and return answers as a hash
  def parsed_answers
    return {} if answers.blank?
    JSON.parse(answers)
  rescue JSON::ParserError
    {}
  end

  # Set answers from a hash
  def set_answers(hash)
    self.answers = hash.to_json
  end

  private

  def set_default_status
    self.status ||= "pending"
  end
  # 🚅 add methods above.
end
