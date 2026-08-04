class FeedsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @site = current_site
    redirect_to new_setup_path and return unless @site
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?

    @space = params[:space]
    @posts = visible_posts_for(@space).includes(:postable).select do |post|
      !post.postable.is_a?(Questionnaire) || post.postable.available_to?(Current.user) || post.postable.manageable_by?(Current.user)
    end
    @post = @site.posts.build(space: @space, visibility: @space == "general" ? :members_only : :everyone)
    @questionnaire = @site.questionnaires.build if @space == "main"
    @questionnaire_templates = QuestionnaireTemplates.keys
    @available_groups = @site.groups.select { |group| group.accessible_to?(Current.user) } if authenticated?
    @available_events = @site.events.select { |event| event.visible_to?(Current.user) } if authenticated?
    prepare_member_tasks if @space == "main" && authenticated?
    @important_announcement_email_available = !Rails.env.production? || (
      Rails.application.config.action_mailer.delivery_method == :smtp && Rails.application.config.action_mailer.perform_deliveries
    )
  end

  private

  def prepare_member_tasks
    @rsvp_invitations = Current.user.invitee&.event_invitations&.includes(:event)&.select { |invitation| invitation.pending? && invitation.event.visible_to?(Current.user) } || []
    @open_questionnaires = @site.questionnaires.published.order(:closes_at, :created_at).select do |questionnaire|
      questionnaire.open_for_responses? && questionnaire.available_to?(Current.user)
    end.first(3)
  end
end
