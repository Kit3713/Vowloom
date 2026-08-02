class CoupleInboxesController < ApplicationController
  before_action :require_live_site!, only: :create
  helper_method :site_manager?

  def index
    @conversations = if site_manager?
      current_site.posts.couple_inbox.visible.chronological
    else
      Current.user.posts.couple_inbox.visible.chronological
    end
    @conversation = current_site.posts.build(space: :couple_inbox)
  end

  def create
    conversation = current_site.posts.build(conversation_params.merge(user: Current.user, space: :couple_inbox, visibility: :members_only, published_at: Time.current))
    if conversation.save
      redirect_to couple_inbox_conversation_path(conversation), notice: "Your message has been sent privately to the couple."
    else
      @conversations = Current.user.posts.couple_inbox.visible.chronological
      @conversation = conversation
      render :index, status: :unprocessable_content
    end
  end

  def show
    @conversation = current_site.posts.couple_inbox.visible.find(params[:id])
    return redirect_to(couple_inbox_path, alert: "That conversation is private.") unless @conversation.accessible_to?(Current.user)

    @comments = @conversation.comments.visible
  end

  private

  def conversation_params
    params.require(:post).permit(:title, :body)
  end

  def site_manager?
    Current.user.owner? || Current.user.admin?
  end
end
