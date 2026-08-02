class ArchiveSearchController < ApplicationController
  allow_unauthenticated_access

  def show
    @site = current_site
    return redirect_to(new_setup_path) unless @site
    return redirect_to(community_path, alert: "Archive search is available after the community is frozen.") unless @site.content_frozen?
    return redirect_to(new_session_path, alert: "Sign in to search this private wedding archive.") if @site.private_access? && !authenticated?

    @query = params[:q].to_s.strip
    @results = @query.present? ? matching_posts : []
  end

  private

  def matching_posts
    term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    candidates = @site.posts.visible
                      .where("posts.title ILIKE :term OR posts.body ILIKE :term", term:)
                      .includes(:user, :group)
                      .order(published_at: :desc)
                      .limit(200)
    candidates.select { |post| visible_to_current_viewer?(post) }.first(50)
  end

  def visible_to_current_viewer?(post)
    return post.accessible_to?(Current.user) if authenticated?

    post.everyone? && !post.couple_inbox? && (post.group.blank? || post.group.site_wide?)
  end
end
