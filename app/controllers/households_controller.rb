class HouseholdsController < ApplicationController
  before_action :require_site_manager!
  before_action :require_live_site!

  def create
    household = current_site.households.build(household_params)
    if household.save
      redirect_to management_path, notice: "Household added."
    else
      redirect_to management_path, alert: household.errors.full_messages.to_sentence
    end
  end

  private

  def require_site_manager!
    return if Current.user.owner? || Current.user.admin?

    redirect_to community_path, alert: "Only owners and admins can manage invitees."
  end

  def household_params
    params.require(:household).permit(:name)
  end
end
