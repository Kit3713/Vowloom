class ApplicationController < ActionController::Base
  include Authentication
  include SiteAccess
  prepend_before_action :require_initial_setup
  around_action :use_wedding_time_zone
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def require_initial_setup
    return if controller_path == "setup" || request.path == rails_health_check_path
    return if Site.exists?

    redirect_to new_setup_path
  end

  def use_wedding_time_zone(&action)
    Time.use_zone(Site.first&.time_zone || "UTC", &action)
  end
end
