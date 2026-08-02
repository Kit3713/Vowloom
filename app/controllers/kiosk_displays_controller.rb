class KioskDisplaysController < ApplicationController
  before_action :require_live_site!, only: :create

  def index
    return redirect_to(community_path, alert: "Only staff can manage displays.") unless staff?
    @displays = current_site.kiosk_displays.order(:name)
    @display = current_site.kiosk_displays.build
  end

  def create
    return redirect_to(kiosk_displays_path, alert: "Only staff can create displays.") unless staff?
    display = current_site.kiosk_displays.build(display_params.merge(created_by: Current.user))
    if display.save
      redirect_to kiosk_displays_path, notice: "Display created. Its link is ready to use."
    else
      redirect_to kiosk_displays_path, alert: display.errors.full_messages.to_sentence
    end
  end

  def update
    return redirect_to(kiosk_displays_path, alert: "Only owners and admins can change display links.") unless site_manager?

    display = current_site.kiosk_displays.find(params[:id])
    if params[:regenerate] == "1"
      display.regenerate_access_token
      message = "Display link replaced. The prior link no longer works."
    else
      display.update!(display_params)
      message = display.enabled? ? "Display updated." : "Display disabled. Its link is no longer usable."
    end
    redirect_to kiosk_displays_path, notice: message
  end

  private

  def staff?
    authenticated? && (Current.user.owner? || Current.user.admin? || Current.user.helper?)
  end

  def site_manager?
    authenticated? && (Current.user.owner? || Current.user.admin?)
  end

  def display_params
    params.require(:kiosk_display).permit(:name, :mode, :show_qr_placeholder, :enabled, :refresh_seconds)
  end
end
