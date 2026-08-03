class ChatController < ApplicationController
  def show
    @site = current_site
    redirect_to new_setup_path and return unless @site
    @conversation = @site.posts.find_by(conversation: true)
  end

  def create
    require_live_site!
    return redirect_to(chat_path, alert: "Only staff can open the wedding chat.") unless staff?
    @conversation = current_site.posts.create!(user: Current.user, space: :main, visibility: :members_only, title: "Wedding chat", body: "Welcome to the wedding chat.", comments_enabled: true, conversation: true, published_at: Time.current)
    redirect_to chat_path, notice: "Wedding chat is open."
  rescue ActiveRecord::RecordNotUnique
    redirect_to chat_path
  end

  private

  def staff?
    authenticated? && (Current.user.owner? || Current.user.admin? || Current.user.helper?)
  end
end
