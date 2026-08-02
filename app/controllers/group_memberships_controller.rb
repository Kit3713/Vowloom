class GroupMembershipsController < ApplicationController
  before_action :require_live_site!
  before_action :set_group

  def create
    return redirect_to(@group, alert: "Only this group's managers can change membership.") unless manage_group?

    user = current_site.users.find(params.require(:user_id))
    @group.group_memberships.find_or_create_by!(user: user)
    redirect_to @group, notice: "#{user.display_name} can now access this group."
  end

  def destroy
    return redirect_to(@group, alert: "Only this group's managers can change membership.") unless manage_group?

    membership = @group.group_memberships.find(params[:id])
    membership.destroy!
    redirect_to @group, notice: "Member removed from the group."
  end

  private

  def set_group
    @group = current_site.groups.find(params[:group_id])
  end

  def manage_group?
    Current.user.owner? || Current.user.admin? || @group.created_by == Current.user
  end
end
