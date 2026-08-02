class RsvpsController < ApplicationController
  before_action :require_live_site!

  def update
    invitation = invitation_for_current_user
    return redirect_to(events_path, alert: "You are not invited to that event.") unless invitation

    invitation.update!(rsvp_params.merge(responded_at: Time.current))
    redirect_to event_path(invitation.event), notice: "Your RSVP has been updated."
  end

  private

  def rsvp_params
    attributes = params[:rsvp].presence || params
    attributes.permit(:rsvp_status, :meal_choice, :dietary_notes, :accessibility_notes)
  end

  def invitation_for_current_user
    invitee = Current.user.invitee
    return unless invitee

    invitation = invitee.event_invitations.find_by(event_id: params[:event_id])
    requested_invitee_id = params.dig(:rsvp, :invitee_id).presence
    return invitation unless requested_invitee_id
    return unless invitee.household_id

    EventInvitation.joins(:invitee).find_by(event_id: params[:event_id], invitees: { id: requested_invitee_id, household_id: invitee.household_id })
  end
end
