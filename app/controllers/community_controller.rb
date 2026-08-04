class CommunityController < ApplicationController
  allow_unauthenticated_access

  def show
    @site = Site.first
    redirect_to new_setup_path and return unless @site
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?

    @space = "main"
    @posts = visible_posts_for(@space).includes(:postable).select do |post|
      !post.postable.is_a?(Questionnaire) || post.postable.available_to?(Current.user) || post.postable.manageable_by?(Current.user)
    end
    @post = Post.new(space: :main, visibility: :everyone)
    @questionnaire = @site.questionnaires.build
    @questionnaire_templates = QuestionnaireTemplates.keys
    @important_announcement_email_available = !Rails.env.production? || (Rails.application.config.action_mailer.delivery_method == :smtp && Rails.application.config.action_mailer.perform_deliveries)
    if authenticated?
      @available_groups = @site.groups.select { |group| group.accessible_to?(Current.user) }
      @available_events = @site.events.select { |event| event.visible_to?(Current.user) }
      @rsvp_invitations = Current.user.invitee&.event_invitations&.includes(:event)&.select { |invitation| invitation.pending? && invitation.event.visible_to?(Current.user) } || []
      @open_questionnaires = @site.questionnaires.published.order(:closes_at, :created_at).select { |questionnaire| questionnaire.open_for_responses? && questionnaire.available_to?(Current.user) }.first(3)
    end
    render "feeds/show"
  end
end
