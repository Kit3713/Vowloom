class SetupController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to new_setup_path, alert: "Please wait before trying setup again." }

  def new
    redirect_to root_path if Site.exists?
    @site = Site.new(accent_color: "#8f4f6a")
    @owner = User.new
  end

  def create
    redirect_to root_path and return if Site.exists?
    @site = Site.new(site_params)
    @owner = @site.users.build(owner_params.merge(role: :owner))

    Site.transaction { @site.save!; @owner.save! }
    start_new_session_for(@owner)
    redirect_to community_path, notice: "Your wedding community is ready."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  private

  def site_params
    params.require(:site).permit(:name, :wedding_date, :landing_message, :accent_color, :access_policy)
  end

  def owner_params
    params.require(:owner).permit(:display_name, :login_identifier, :recovery_email, :password, :password_confirmation)
  end
end
