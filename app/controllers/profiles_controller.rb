class ProfilesController < ApplicationController
  before_action :require_live_site!, only: :update

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    if @user.update(profile_params)
      redirect_to community_path, notice: "Your profile has been updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.require(:user).permit(:display_name, :profile_summary, :profile_photo, :recovery_email, :important_announcement_emails)
  end
end
