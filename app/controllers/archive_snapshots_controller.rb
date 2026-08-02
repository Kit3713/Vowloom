class ArchiveSnapshotsController < ApplicationController
  before_action :require_owner!

  def index
    @snapshots = current_site.archive_snapshots.includes(:created_by).order(frozen_at: :desc)
  end

  def export
    snapshot = current_site.archive_snapshots.find(params[:id])
    include_private = params[:include_private] == "1"
    filename = "vowloom-#{include_private ? 'complete' : 'public-safe'}-content-export-#{snapshot.frozen_at.to_date}.json"
    send_data JSON.pretty_generate(snapshot.export_payload(include_private:)), filename:, type: "application/json", disposition: "attachment"
  end

  def readable_export
    snapshot = current_site.archive_snapshots.find(params[:id])
    @include_private = params[:include_private] == "1"
    @payload = snapshot.export_payload(include_private: @include_private)
    filename = "vowloom-#{@include_private ? 'complete' : 'public-safe'}-readable-archive-#{snapshot.frozen_at.to_date}.html"
    html = render_to_string(template: "archive_snapshots/readable_export", formats: [ :html ], layout: false)

    send_data html, filename:, type: "text/html; charset=utf-8", disposition: "attachment"
  end

  private

  def require_owner!
    return if Current.user.owner?

    redirect_to community_path, alert: "Only the site owner can access archive exports."
  end
end
