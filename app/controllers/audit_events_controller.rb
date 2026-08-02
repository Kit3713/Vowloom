class AuditEventsController < ApplicationController
  before_action :require_site_manager!

  def index
    @events = current_site.audit_events.includes(:actor, :auditable).order(created_at: :desc).limit(250)
  end

  private

  def require_site_manager!
    return if Current.user.owner? || Current.user.admin?

    redirect_to community_path, alert: "Only owners and admins can view the audit log."
  end
end
