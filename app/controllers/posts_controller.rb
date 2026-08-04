class PostsController < ApplicationController
  before_action :require_live_site!

  def create
    @site = current_site
    space = params.require(:post).fetch(:space)
    group = space == "group_space" ? @site.groups.find_by(id: params.dig(:post, :group_id)) : nil
    return unless authorize_space!(space, group)

    @post = @site.posts.build(content_params.merge(user: Current.user, group:, space:, post_type: :story, published_at: Time.current))
    build_post_elements
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

  def destroy
    post = current_site.posts.find(params[:id])
    return redirect_to(comment_fallback(post), alert: "You cannot delete that post.") unless post.manageable_by?(Current.user)

    post.update!(hidden_at: Time.current)
    record_audit!("post.deleted", auditable: post, metadata: { space: post.space, recoverable: true })
    redirect_to comment_fallback(post), notice: "Post deleted. An Owner or Admin can recover it from moderation records."
  end

  private

  def post_params
    params.require(:post).permit(
      :title, :body, :visibility, :comments_enabled, :group_id, :space,
      post_blocks_attributes: [ :kind, :title, :body, :interactive, :options_text, :capacity, :resource_key, :audience, :results_visibility, :response_edit_policy, :opens_at, :closes_at, :address, :map_url, { files: [] } ]
    )
  end

  def content_params
    post_params.except(:post_blocks_attributes, :space)
  end

  def create_post_with_attachments
    Post.transaction do
      @post.save!
      @post.post_blocks.select(&:media?).each { |block| block.materialize_media!(site: @site, user: Current.user) }
      @announcement_delivery_ids = @post.queue_important_announcement_emails!(actor: Current.user) if important_announcement_email_requested?
    end
    @announcement_delivery_ids&.each { |delivery_id| ImportantAnnouncementDeliveryJob.perform_later(delivery_id) }
    true
  rescue ActiveRecord::RecordInvalid => error
    @post.errors.add(:base, error.record.errors.full_messages.to_sentence) unless error.record == @post
    false
  end

  def build_post_elements
    raw_elements = post_params[:post_blocks_attributes]
    elements = raw_elements.respond_to?(:values) ? raw_elements.values : Array(raw_elements)
    elements.first(30).each_with_index do |raw, index|
      attributes = raw.to_h.with_indifferent_access
      files = Array(attributes.delete(:files)).reject(&:blank?)
      options = attributes.delete(:options_text).to_s.lines.map(&:strip).reject(&:blank?)
      resource_key = attributes.delete(:resource_key).to_s
      settings = {
        "options" => options,
        "items" => options.map { |text| { "id" => SecureRandom.hex(6), "text" => text, "done" => false } },
        "grid" => Array.new(4) { Array.new(3, "") },
        "interactive" => ActiveModel::Type::Boolean.new.cast(attributes.delete(:interactive)),
        "audience" => attributes.delete(:audience).presence_in(%w[members staff]) || "members",
        "results_visibility" => attributes.delete(:results_visibility).presence_in(%w[participants members staff]) || "participants",
        "response_edit_policy" => attributes.delete(:response_edit_policy).presence_in(%w[editable locked]) || "editable",
        "capacity" => attributes.delete(:capacity).to_i,
        "address" => attributes.delete(:address).to_s,
        "map_url" => attributes.delete(:map_url).to_s
      }
      block = @post.post_blocks.build(attributes.slice(:kind, :title, :body, :opens_at, :closes_at).merge(created_by: Current.user, position: index + 1, settings:))
      assign_element_resource(block, resource_key)
      block.files.attach(files)
    end
  end

  def assign_element_resource(block, resource_key)
    type, id = resource_key.split(":", 2)
    block.blockable = case type
    when "Questionnaire" then @site.questionnaires.find_by(id:)
    when "Event" then @site.events.find_by(id:)
    when "Album" then @site.albums.find_by(id:)
    end
  end

  def authorize_space!(space, group)
    allowed = case space
    when "main" then Current.user.owner? || Current.user.admin? || Current.user.helper?
    when "general" then Current.user.member? || Current.user.helper? || Current.user.admin? || Current.user.owner?
    when "group_space" then authenticated? && group&.accessible_to?(Current.user)
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

  def comment_fallback(post)
    return group_path(post.group) if post.group_space?

    feed_path(post.space)
  end

  def important_announcement_email_available?
    return true unless Rails.env.production?

    Rails.application.config.action_mailer.delivery_method == :smtp && Rails.application.config.action_mailer.perform_deliveries
  end
end
