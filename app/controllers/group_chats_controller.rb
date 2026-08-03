class GroupChatsController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :set_group

  def show
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if @site.private_access? && !authenticated?
    return redirect_to(groups_path, alert: "That group is private.") unless @group.accessible_to?(Current.user)

    @conversation = @group.posts.visible.find_by(conversation: true)
  end

  def create
    require_live_site!
    return redirect_to(@group, alert: "Only group staff can open a live chat.") unless manage_group?

    @conversation = @group.posts.create!(site: @site, user: Current.user, space: :group_space, visibility: @group.private_group? ? :members_only : :everyone, title: "#{@group.name} chat", body: "Welcome to the #{@group.name} chat.", comments_enabled: true, conversation: true, published_at: Time.current)
    redirect_to group_chat_path(@group), notice: "Group chat is open."
  rescue ActiveRecord::RecordNotUnique
    redirect_to group_chat_path(@group)
  end

  private

  def set_group
    @site = current_site
    return redirect_to(new_setup_path) unless @site

    @group = @site.groups.find(params[:group_id])
  end

  def manage_group?
    authenticated? && (Current.user.owner? || Current.user.admin? || @group.created_by == Current.user)
  end
end
