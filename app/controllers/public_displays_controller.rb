class PublicDisplaysController < ApplicationController
  allow_unauthenticated_access

  def show
    @display = KioskDisplay.find_by!(access_token: params[:token], enabled: true)
    @site = @display.site
    @events = @site.events.site_wide.where("starts_at >= ?", Time.current).order(:starts_at).limit(5)
    @current_event = @site.events.site_wide.where("starts_at <= ?", Time.current).where("ends_at IS NULL OR ends_at >= ?", Time.current).order(starts_at: :desc).first
    @next_event = @events.first
    @media_assets = @site.media_assets.approved.where(featured: true).with_attached_file.order(created_at: :desc).limit(24)
    @announcements = @site.posts.visible.main.everyone.chronological.limit(4)
    @slideshow_asset = @media_assets[(Time.current.to_i / @display.refresh_seconds) % @media_assets.size] if @media_assets.any?
  end
end
