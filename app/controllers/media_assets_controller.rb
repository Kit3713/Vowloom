class MediaAssetsController < ApplicationController
  allow_unauthenticated_access only: :download
  before_action :require_live_site!, except: :download

  def create
    media_asset = current_site.media_assets.build(media_params.merge(user: Current.user))
    media_asset.status = :approved if staff?
    if media_asset.save
      redirect_to gallery_path, notice: "Upload received."
    else
      redirect_to gallery_path, alert: media_asset.errors.full_messages.to_sentence
    end
  end

  def update
    return redirect_to(gallery_path, alert: "Only staff can curate media.") unless staff?
    media_asset = current_site.media_assets.find(params[:id])
    return redirect_to(gallery_path, alert: "Helpers can only curate their own uploads.") if Current.user.helper? && media_asset.user != Current.user

    media_asset.update!(curation_params)
    if media_asset.approved? && params[:album_id].present?
      album = current_site.albums.find(params[:album_id])
      album.media_assets << media_asset unless album.media_assets.exists?(media_asset.id)
    end
    redirect_to gallery_path, notice: "Media updated."
  end

  def download
    return redirect_to(new_session_path, alert: "Please sign in with your wedding invitation.") if current_site.private_access? && !authenticated?

    media_asset = current_site.media_assets.approved.with_attached_file.find(params[:id])
    return redirect_to(gallery_path, alert: "That media is not available to you.") unless media_asset.accessible_to?(Current.user)
    if params[:original] == "1"
      return redirect_to(gallery_path, alert: "Only staff can download original files.") unless staff?

      return redirect_to rails_blob_path(media_asset.file, disposition: "attachment")
    end

    return redirect_to rails_blob_path(media_asset.file, disposition: "attachment") unless media_asset.image?

    variant = media_asset.file.variant(resize_to_limit: [ 2_000, 2_000 ])
    redirect_to rails_representation_path(variant, disposition: "attachment")
  end

  private

  def staff?
    Current.user.owner? || Current.user.admin? || Current.user.helper?
  end

  def media_params
    params.require(:media_asset).permit(:file, :caption, :credit)
  end

  def curation_params
    permitted = params.fetch(:media_asset, {}).permit(:caption, :credit, :featured)
    action = params[:moderation_action].presence_in(%w[approve hide]) || "approve"
    permitted.merge(status: action == "hide" ? :hidden : :approved)
  end
end
