class CommunityController < ApplicationController
  allow_unauthenticated_access

  def show
    @site = Site.first
    redirect_to new_setup_path and return unless @site
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?

    @announcements = visible_announcements
    @upcoming_events = @site.events.order(:starts_at).select { |event| event.visible_to?(Current.user) && (event.starts_at.blank? || event.starts_at >= Time.current) }.first(3)
    return unless authenticated?

    @rsvp_invitations = Current.user.invitee&.event_invitations&.includes(:event)&.select { |invitation| invitation.pending? && invitation.event.visible_to?(Current.user) } || []
    @open_questionnaires = @site.questionnaires.published.order(:closes_at, :created_at).select do |questionnaire|
      questionnaire.open_for_responses? && questionnaire.available_to?(Current.user)
    end.first(3)
  end

  private

  def visible_announcements
    posts = @site.posts.visible.main
    posts = posts.where(visibility: :everyone) unless authenticated?
    posts.chronological.limit(3)
  end
end
