module SiteAccess
  extend ActiveSupport::Concern

  included do
    helper_method :current_site
  end

  private

  def current_site
    @current_site ||= Site.first
  end

  def require_live_site!
    redirect_to community_path, alert: "This wedding site is frozen and no longer accepts changes." if current_site.content_frozen?
  end

  def visible_posts_for(space)
    posts = current_site.posts.visible.where(space:)
    posts = posts.where(visibility: :everyone) unless authenticated?
    posts.chronological
  end

  def record_audit!(action, auditable: nil, metadata: {})
    current_site.audit_events.create!(actor: Current.user, action:, auditable:, metadata:)
  end
end
