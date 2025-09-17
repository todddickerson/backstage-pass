class Account::TeamsController < Account::ApplicationController
  before_action :set_team, only: [:show]

  def index
    @teams = current_user.teams
    redirect_to account_team_path(@teams.first) if @teams.count == 1
  end

  def show
    @spaces = @team.spaces
    @access_grants = @team.access_grants
    @billing_purchases = @team.billing_purchases
  end

  private

  def set_team
    @team = current_user.teams.find(params[:id])
  end

  def permitted_fields
    [
      # 🚅 super scaffolding will insert new fields above this line.
    ]
  end

  def permitted_arrays
    {
      # 🚅 super scaffolding will insert new arrays above this line.
    }
  end

  def process_params(strong_params)
    # 🚅 super scaffolding will insert processing for new fields above this line.
    strong_params
  end
end
