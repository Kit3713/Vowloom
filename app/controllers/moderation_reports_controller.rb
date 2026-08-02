class ModerationReportsController < ApplicationController
  before_action :require_live_site!

  def create
    reportable = reportable_from_params
    report = current_site.moderation_reports.build(reporter: Current.user, reportable: reportable, reason: params[:reason].presence || "Member report")
    if report.save
      redirect_back fallback_location: community_path, notice: "Thanks. The report has been sent to the site managers."
    else
      redirect_back fallback_location: community_path, alert: report.errors.full_messages.to_sentence
    end
  end

  private

  def reportable_from_params
    case params.require(:reportable_type)
    when "Post" then current_site.posts.find(params.require(:reportable_id))
    when "Comment" then Comment.joins(:post).where(posts: { site_id: current_site.id }).find(params.require(:reportable_id))
    when "MediaAsset" then current_site.media_assets.find(params.require(:reportable_id))
    else raise ActiveRecord::RecordNotFound
    end
  end
end
