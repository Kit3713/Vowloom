class GroupsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_site

  def index
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?
    @groups = @site.groups.includes(:members).select { |group| group.accessible_to?(Current.user) }
    @group = @site.groups.build
  end

  def show
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if @site.private_access? && !authenticated?

    @group = @site.groups.find(params[:id])
    return redirect_to(groups_path, alert: "That group is private.") unless @group.accessible_to?(Current.user)
    @conversation = @group.posts.visible.find_by(conversation: true) if @group.discussion?
    @posts = @group.posts.visible.where(conversation: false).chronological
    @post = @group.posts.build(space: :group_space, visibility: @group.private_group? ? :members_only : :everyone)
    @available_members = @site.users.order(:display_name) if manage_group?(@group)
    @task = @group.tasks.build
    @tasks = @group.tasks.includes(:assigned_user, task_comments: :user).order(Arel.sql("completed_at IS NULL DESC"), :due_on, :created_at)
  end

  def create
    require_live_site!
    return redirect_to(groups_path, alert: "Only staff can create groups.") unless staff?
    @group = @site.groups.build(group_params.merge(created_by: Current.user))
    if @group.save
      @group.members << Current.user unless @group.members.include?(Current.user)
      redirect_to @group, notice: "Group created."
    else
      @groups = @site.groups
      render :index, status: :unprocessable_content
    end
  end

  private

  def set_site
    @site = current_site
    redirect_to new_setup_path and return unless @site
  end

  def staff?
    authenticated? && (Current.user.owner? || Current.user.admin? || Current.user.helper?)
  end

  def group_params
    params.require(:group).permit(:name, :description, :visibility, :participation, :event_id)
  end

  def manage_group?(group)
    authenticated? && (Current.user.owner? || Current.user.admin? || group.created_by == Current.user)
  end
end
