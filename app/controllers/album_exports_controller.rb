class AlbumExportsController < ApplicationController
  def create
    @album = current_site.albums.find(params[:album_id])
    return redirect_to(gallery_path, alert: "That album is not available to you.") unless @album.accessible_to?(Current.user)

    AlbumExport.purge_expired!(current_site)
    assets = @album.exportable_media_assets_for(Current.user)
    return redirect_to(gallery_path(anchor: album_anchor), alert: "This album has no media you can download.") if assets.empty?

    include_originals = params[:include_originals] == "1" && staff?
    export = @album.album_exports.create!(
      requested_by: Current.user,
      include_originals:,
      expires_at: AlbumExport::DOWNLOAD_LIFETIME.from_now
    )
    AlbumZipExportJob.perform_later(export)
    record_audit!("album_export.requested", auditable: @album, metadata: { album_export_id: export.id, originals: include_originals, media_count: assets.length })

    redirect_to gallery_path(anchor: album_anchor), notice: "Preparing your album download. Refresh this page in a moment."
  end

  def download
    @album = current_site.albums.find(params[:album_id])
    export = @album.album_exports.find(params[:id])
    return redirect_to(gallery_path, alert: "That album download is not available to you.") unless export.downloadable_by?(Current.user)

    send_data export.archive.download,
      filename: export.archive.filename.to_s,
      type: "application/zip",
      disposition: "attachment"
  end

  private

  def staff?
    Current.user.owner? || Current.user.admin? || Current.user.helper?
  end

  def album_anchor
    ActionView::RecordIdentifier.dom_id(@album)
  end
end
