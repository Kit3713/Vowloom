class CommentsController < ApplicationController
  before_action :require_live_site!

  def create
    post = current_site.posts.visible.find(params[:post_id])
    return redirect_to(feed_path(post.space), alert: "Comments are disabled on this post.") unless post.comments_enabled?
    return redirect_to(new_session_path, alert: "Sign in to join the conversation.") unless authenticated?
    return redirect_to(comment_fallback(post), alert: "You cannot reply to that conversation.") unless post.commentable_by?(Current.user)

    parent = parent_comment(post)
    comment = post.comments.build(user: Current.user, body: comment_params[:body], parent:)
    if create_comment_with_media(comment, post)
      broadcast_comment(post, comment)
      redirect_back fallback_location: comment_fallback(post), notice: "Comment added."
    else
      redirect_back fallback_location: comment_fallback(post), alert: comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    comment = Comment.joins(:post).where(posts: { site_id: current_site.id }).find(params[:id])
    post = comment.post
    allowed = comment.user == Current.user || Current.user.owner? || Current.user.admin? || Current.user.helper?
    return redirect_to(comment_fallback(post), alert: "You cannot delete that comment.") unless allowed

    comment.update!(hidden_at: Time.current)
    record_audit!("comment.deleted", auditable: comment, metadata: { post_id: post.id, recoverable: true })
    redirect_to comment_fallback(post), notice: "Comment deleted."
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :parent_id, files: [])
  end

  def parent_comment(post)
    return if comment_params[:parent_id].blank?

    parent = post.comments.visible.find(comment_params[:parent_id])
    parent.parent || parent
  end

  def create_comment_with_media(comment, post)
    files = comment_params.fetch(:files, []).reject(&:blank?)
    if files.length > 4
      comment.errors.add(:base, "Attach no more than four photos or videos to one comment")
      return false
    end

    Comment.transaction do
      assets = files.map do |file|
        comment.media_assets.build(
          site: current_site,
          user: Current.user,
          post:,
          file:,
          status: Current.user.owner? || Current.user.admin? || Current.user.helper? ? :approved : :submitted
        )
      end
      comment.save!
      assets.each { |asset| asset.save! unless asset.persisted? }
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    comment.errors.add(:base, error.record.errors.full_messages.to_sentence) unless error.record == comment
    false
  end

  def broadcast_comment(post, comment)
    target = comment.parent ? helpers.dom_id(comment.parent, :replies) : helpers.dom_id(post, :comments)
    Turbo::StreamsChannel.broadcast_append_to(post, target:, partial: "comments/comment", locals: { comment:, interactive: false })
  end

  def comment_fallback(post)
    return couple_inbox_conversation_path(post) if post.couple_inbox?
    return group_path(post.group) if post.group_space?

    feed_path(post.space)
  end
end
