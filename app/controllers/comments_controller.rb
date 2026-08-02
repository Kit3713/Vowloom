class CommentsController < ApplicationController
  before_action :require_live_site!

  def create
    post = current_site.posts.visible.find(params[:post_id])
    return redirect_to(feed_path(post.space), alert: "Comments are disabled on this post.") unless post.comments_enabled?
    return redirect_to(new_session_path, alert: "Sign in to join the conversation.") unless authenticated?
    return redirect_to(comment_fallback(post), alert: "You cannot reply to that conversation.") unless post.commentable_by?(Current.user)

    comment = post.comments.build(user: Current.user, body: params.require(:comment).fetch(:body))
    if comment.save
      Turbo::StreamsChannel.broadcast_append_to(post, target: helpers.dom_id(post, :comments), partial: "comments/comment", locals: { comment: }) if post.conversation?
      redirect_back fallback_location: comment_fallback(post), notice: "Comment added."
    else
      redirect_back fallback_location: comment_fallback(post), alert: comment.errors.full_messages.to_sentence
    end
  end

  def comment_fallback(post)
    return couple_inbox_conversation_path(post) if post.couple_inbox?
    return group_path(post.group) if post.group_space?

    feed_path(post.space)
  end
end
