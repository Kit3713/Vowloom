class InvitationCodesController < ApplicationController
  before_action :require_site_manager!
  before_action :require_live_site!

  def create
    household = current_site.households.find(params.require(:household_id))
    code = InvitationCode.issue_for!(site: current_site, household: household, expires_at: expiration)
    record_audit!("invitation_code.issued", auditable: household)
    redirect_to management_path, notice: "Invitation code for #{household.name}: #{code}. Copy it now; it will not be shown again."
  end

  private

  def require_site_manager!
    return if Current.user.owner? || Current.user.admin?

    redirect_to community_path, alert: "Only owners and admins can issue invitations."
  end

  def expiration
    value = params[:expires_at]
    value.present? ? Time.zone.parse(value) : nil
  rescue ArgumentError
    nil
  end
end
