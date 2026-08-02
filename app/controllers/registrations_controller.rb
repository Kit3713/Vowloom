class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 10.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Please wait before trying again." }

  def new
    @site = Site.first
    redirect_to new_setup_path and return unless @site
    @invitation_code = InvitationCode.find_active(@site, params[:invitation_code])
    @user = User.new
  end

  def create
    @site = Site.first
    redirect_to new_setup_path and return unless @site
    redirect_to root_path, alert: "This wedding archive is no longer accepting new accounts." and return if @site.content_frozen?

    @invitation_code = InvitationCode.find_active(@site, params[:invitation_code])
    invitee = @invitation_code&.household&.invitees&.find_by(id: params[:invitee_id])
    if invitee.nil? || invitee.user.present?
      @user = User.new(registration_params)
      @user.errors.add(:base, "That invitation is invalid, expired, or already linked to an account.")
      return render :new, status: :unprocessable_content
    end

    @user = @site.users.build(registration_params.merge(invitee:, role: :member))
    if @user.save
      @invitation_code.update!(last_used_at: Time.current)
      start_new_session_for(@user)
      redirect_to community_path, notice: "Welcome, #{@user.display_name}!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:user).permit(:display_name, :login_identifier, :recovery_email, :password, :password_confirmation)
  end
end
