class FeedsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @site = current_site
    redirect_to new_setup_path and return unless @site
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?

    @space = params[:space]
    @posts = visible_posts_for(@space)
    @post = Post.new(space: @space, visibility: @space == "general" ? :members_only : :everyone)
  end
end
