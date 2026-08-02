class CommunityController < ApplicationController
  allow_unauthenticated_access

  def show
    @site = Site.first
    redirect_to new_setup_path and return unless @site
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." if @site.private_access? && !authenticated?
  end
end
