class UsersController < ApplicationController
  before_action :require_owner!

  def update
    user = current_site.users.find(params[:id])
    return redirect_to(management_path, alert: "The Owner role cannot be reassigned here.") if user.owner?

    user.update!(role: role_params.fetch(:role))
    record_audit!("user.role_updated", auditable: user, metadata: { role: user.role })
    redirect_to management_path, notice: "#{user.display_name} is now a #{user.role.humanize}."
  end

  private

  def require_owner!
    return if Current.user.owner?

    redirect_to community_path, alert: "Only the site owner can manage roles."
  end

  def role_params
    params.require(:user).permit(:role).tap do |attributes|
      raise ActionController::BadRequest, "Invalid role" unless attributes[:role].in?(%w[admin helper member])
    end
  end
end
