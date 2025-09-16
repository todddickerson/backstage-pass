class Account::CreatorProfilesController < Account::ApplicationController
  before_action :set_creator_profile

  # Show/edit creator profile (singular resource)
  def show
    redirect_to edit_account_creator_profile_path if @creator_profile.blank?
  end

  def edit
    @creator_profile ||= current_user.build_creator_profile
  end

  def update
    @creator_profile ||= current_user.build_creator_profile

    if @creator_profile.update(creator_profile_params)
      redirect_to account_creator_profile_path, notice: "Creator profile updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @creator_profile = current_user.build_creator_profile(creator_profile_params)

    if @creator_profile.save
      redirect_to account_creator_profile_path, notice: "Creator profile created successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_creator_profile
    @creator_profile = current_user.creator_profile
  end

  def creator_profile_params
    params.require(:creators_profile).permit(:username, :display_name, :bio, :website_url)
  end
end
