class PostsController < ApplicationController
  before_action :require_live_site!

  def create
    @site = current_site
    space = params.require(:post).fetch(:space)
    group = space == "group_space" ? @site.groups.find_by(id: params.dig(:post, :group_id)) : nil
    return unless authorize_space!(space, group)

    @post = @site.posts.build(content_params.merge(user: Current.user, group:, space:, published_at: Time.current))
    if create_post_with_attachments
      notice = "Post published."
      if @announcement_delivery_ids.present?
        notice = "Post published. Important-announcement email delivery queued for #{@announcement_delivery_ids.length} opted-in invited members."
      end
      redirect_to(group || feed_path(space), notice:)
    else
      @space = space
      @posts = visible_posts_for(space)
      render "feeds/show", status: :unprocessable_content
    end
  end

  def update
    post = current_site.posts.find(params[:id])
    return redirect_to(feed_path(post.space), alert: "Only owners and admins can pin posts.") unless Current.user.owner? || Current.user.admin?
    return redirect_to(feed_path(post.space), alert: "Only Main posts can be pinned.") unless post.main?

    post.update!(pinned: params.require(:post).fetch(:pinned))
    redirect_to feed_path(post.space), notice: post.pinned? ? "Post pinned." : "Post unpinned."
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :visibility, :comments_enabled, :group_id, files: [])
  end

  def content_params
    post_params.except(:files)
  end

  def create_post_with_attachments
    Post.transaction do
      @post.save!
      post_params.fetch(:files, []).reject(&:blank?).each do |file|
        @post.media_assets.create!(site: @site, user: Current.user, file:, status: Current.user.helper? || Current.user.admin? || Current.user.owner? ? :approved : :submitted)
      end
      @announcement_delivery_ids = @post.queue_important_announcement_emails!(actor: Current.user) if important_announcement_email_requested?
    end
    @announcement_delivery_ids&.each { |delivery_id| ImportantAnnouncementDeliveryJob.perform_later(delivery_id) }
    true
  rescue ActiveRecord::RecordInvalid => error
    @post.errors.add(:base, error.record.errors.full_messages.to_sentence) unless error.record == @post
    false
  end

  def authorize_space!(space, group)
    allowed = case space
    when "main" then Current.user.owner? || Current.user.admin? || Current.user.helper?
    when "general" then Current.user.member? || Current.user.helper? || Current.user.admin? || Current.user.owner?
    when "group_space" then group&.accessible_to?(Current.user) && (group.discussion? || Current.user.owner? || Current.user.admin? || Current.user.helper?)
    else false
    end
    return true if allowed

    redirect_to community_path, alert: "You cannot publish in that space."
    false
  end

  def important_announcement_email_requested?
    return false unless @post.main? && (Current.user.owner? || Current.user.admin?) && important_announcement_email_available?

    ActiveModel::Type::Boolean.new.cast(params.dig(:post, :send_important_announcement_email))
  end

  def important_announcement_email_available?
    return true unless Rails.env.production?

    Rails.application.config.action_mailer.delivery_method == :smtp && Rails.application.config.action_mailer.perform_deliveries
  end
end
