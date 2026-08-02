class ModerationController < ApplicationController
  before_action :require_site_manager!

  def index
    @reports = current_site.moderation_reports.open.includes(:reporter, :reportable).order(created_at: :asc)
  end

  def update
    target = moderation_target
    case params.require(:moderation_action)
    when "hide" then hide!(target)
    when "restore" then restore!(target)
    when "lock" then target.update!(comments_enabled: false) if target.is_a?(Post)
    when "unlock" then target.update!(comments_enabled: true) if target.is_a?(Post)
    else return redirect_to(moderation_path, alert: "Unknown moderation action.")
    end
    current_site.moderation_reports.open.where(reportable: target).update_all(status: ModerationReport.statuses.fetch(:resolved), handled_by_id: Current.user.id, handled_at: Time.current)
    record_audit!("moderation.#{params.require(:moderation_action)}", auditable: target)
    redirect_to moderation_path, notice: "Content updated and related reports resolved."
  end

  private

  def require_site_manager!
    return if Current.user.owner?
    return if current_site.content_live? && Current.user.admin?

    redirect_to community_path, alert: current_site.content_frozen? ? "Only the Owner can redact a frozen archive." : "Only owners and admins can manage reports."
  end

  def moderation_target
    case params.require(:content_type)
    when "Post" then current_site.posts.find(params.require(:id))
    when "Comment" then Comment.joins(:post).where(posts: { site_id: current_site.id }).find(params.require(:id))
    when "MediaAsset" then current_site.media_assets.find(params.require(:id))
    else raise ActiveRecord::RecordNotFound
    end
  end

  def hide!(target)
    target.is_a?(MediaAsset) ? target.update!(status: :hidden) : target.update!(hidden_at: Time.current)
  end

  def restore!(target)
    target.is_a?(MediaAsset) ? target.update!(status: :approved) : target.update!(hidden_at: nil)
  end
end
