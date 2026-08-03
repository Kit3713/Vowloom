class ManagementController < ApplicationController
  before_action :require_owner!

  def show
    @site = current_site
    @household = @site.households.build
    @invitee = @site.invitees.build
    @households = @site.households.includes(:invitees).order(:name)
    @users = @site.users.order(:role, :display_name)
  end

  def update
    @site = current_site
    was_live = @site.content_live?
    if @site.update(site_params)
      if was_live && @site.content_frozen?
        snapshot = ArchiveSnapshot.capture!(site: @site, actor: Current.user)
        record_audit!("site.frozen", auditable: snapshot)
      else
        record_audit!("site.updated", auditable: @site)
      end
      redirect_to management_path, notice: @site.content_frozen? ? "Vowloom is now frozen as a read-only archive." : "Vowloom settings saved."
    else
      @household = @site.households.build
      @invitee = @site.invitees.build
      @households = @site.households.includes(:invitees).order(:name)
      @users = @site.users.order(:role, :display_name)
      render :show, status: :unprocessable_content
    end
  end

  def transfer_ownership
    @site = current_site
    new_owner = @site.users.find(params.require(:target_user_id))
    _previous_owner, new_owner = @site.transfer_ownership!(from: Current.user, to: new_owner)
    redirect_to community_path, notice: "Ownership transferred to #{new_owner.display_name}. You remain an administrator."
  rescue ActionController::ParameterMissing, ActiveRecord::RecordNotFound, Site::OwnershipTransferError => error
    redirect_to management_path, alert: "Ownership transfer was not completed: #{error.message}"
  end

  private

  def require_owner!
    return if authenticated? && Current.user.owner?

    redirect_to community_path, alert: "Only the site owner can manage Vowloom."
  end

  def site_params
    params.require(:site).permit(:name, :wedding_date, :landing_message, :accent_color, :access_policy, :content_state, :banner_image, :media_quota_gigabytes)
  end
end
