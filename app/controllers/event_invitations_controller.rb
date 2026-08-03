class EventInvitationsController < ApplicationController
  before_action :require_live_site!
  before_action :set_event
  before_action :require_site_manager!

  def create
    invitee = current_site.invitees.find(params.require(:invitee_id))
    @event.event_invitations.find_or_create_by!(invitee: invitee)
    record_audit!("event_invitation.created", auditable: @event, metadata: { invitee_id: invitee.id })
    redirect_to @event, notice: "#{invitee.full_name} has been invited."
  end

  def destroy
    invitation = @event.event_invitations.find(params[:id])
    invitation.destroy!
    record_audit!("event_invitation.removed", auditable: @event, metadata: { invitee_id: invitation.invitee_id })
    redirect_to @event, notice: "Invitation removed."
  end

  def update
    invitation = @event.event_invitations.find(params[:id])
    invitation.update!(rsvp_params.merge(responded_at: Time.current))
    record_audit!("event_invitation.rsvp_updated", auditable: @event, metadata: {
      invitee_id: invitation.invitee_id,
      rsvp_status: invitation.rsvp_status,
      staff_entered: true,
      changed_fields: invitation.previous_changes.except("updated_at", "responded_at").keys
    })
    redirect_to @event, notice: "RSVP updated for #{invitation.invitee.full_name}."
  end

  private

  def set_event
    @event = current_site.events.find(params[:event_id])
  end

  def require_site_manager!
    return if Current.user.owner? || Current.user.admin?

    redirect_to @event, alert: "Only owners and admins can manage invitations."
  end

  def rsvp_params
    params.require(:event_invitation).permit(:rsvp_status, :meal_choice, :dietary_notes, :accessibility_notes)
  end
end
