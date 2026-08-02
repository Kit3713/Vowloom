class GalleryController < ApplicationController
  allow_unauthenticated_access

  def index
    @site = current_site
    redirect_to new_setup_path and return unless @site
    redirect_to new_session_path, alert: "Please sign in with your wedding invitation." and return if @site.private_access? && !authenticated?
    @albums = @site.albums.where(visibility: authenticated? ? %i[everyone members_only] : :everyone).order(featured: :desc, created_at: :desc)
    @media_assets = @site.media_assets.approved.where(featured: true).with_attached_file.order(created_at: :desc)
    @submitted_assets = if site_manager?
      @site.media_assets.submitted.with_attached_file.order(created_at: :asc)
    elsif helper?
      @site.media_assets.submitted.where(user: Current.user).with_attached_file.order(created_at: :asc)
    else
      []
    end
    @album = @site.albums.build
    @media_asset = @site.media_assets.build
    @curation_albums = @site.albums.order(:title) if staff?
    @media_bytes_used = @site.media_bytes_used
  end

  private

  def staff?
    authenticated? && (Current.user.owner? || Current.user.admin? || Current.user.helper?)
  end

  def site_manager?
    authenticated? && (Current.user.owner? || Current.user.admin?)
  end

  def helper?
    authenticated? && Current.user.helper?
  end
end
