class GroupChatsController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :set_group

  def show
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if @site.private_access? && !authenticated?
    return redirect_to(groups_path, alert: "That group is private.") unless @group.accessible_to?(Current.user)
    redirect_to @group, status: :moved_permanently
  end

  def create
    redirect_to @group, notice: "Posts and threaded conversations now live together in the group."
  end

  private

  def set_group
    @site = current_site
    return redirect_to(new_setup_path) unless @site

    @group = @site.groups.find(params[:group_id])
  end
end
