require "digest"

class ArchiveSnapshot < ApplicationRecord
  MANIFEST_VERSION = 2

  belongs_to :site
  belongs_to :created_by, class_name: "User"

  validates :checksum, :frozen_at, presence: true

  def self.capture!(site:, actor:)
    captured_at = Time.current
    counts = content_counts_for(site)
    public_payload = build_payload(site, counts:, captured_at:)
    private_payload = build_payload(site, counts:, captured_at:, include_private: true)

    create!(
      site:,
      created_by: actor,
      manifest_version: MANIFEST_VERSION,
      content_counts: counts,
      public_payload:,
      private_payload:,
      checksum: checksum_for(public_payload:, private_payload:),
      frozen_at: captured_at
    )
  end

  def export_payload(include_private: false)
    payload = include_private ? private_payload : public_payload
    return payload.deep_symbolize_keys.merge(checksum:) if payload.present?

    # Snapshots made before payload persistence was introduced remain exportable.
    # Their data is reconstructed from the current site and should be re-frozen to
    # obtain an immutable preservation record.
    self.class.build_payload(site, counts: content_counts, captured_at: created_at, include_private:).merge(checksum:)
  end

  def self.build_payload(site, counts:, captured_at:, include_private: false)
    posts = published_posts_for(site, include_private:)
    media = site.media_assets.approved.with_attached_file.order(:created_at)
    media = media.where(post_id: posts.select(:id)).or(media.where(post_id: nil)) unless include_private
    events = include_private ? site.events : site.events.site_wide
    groups = include_private ? site.groups : site.groups.site_wide

    {
      format: "vowloom-portable-content-export",
      manifest_version: MANIFEST_VERSION,
      generated_at: captured_at.iso8601,
      frozen_at: captured_at.iso8601,
      site: { name: site.name, wedding_date: site.wedding_date, landing_message: site.landing_message, accent_color: site.accent_color },
      content_counts: counts,
      events: events.order(:starts_at).map { |event| { title: event.title, description: event.description, starts_at: event.starts_at, ends_at: event.ends_at, location_name: event.location_name, location_address: event.location_address, visibility: event.visibility } },
      groups: groups.order(:name).map { |group| { name: group.name, description: group.description, visibility: group.visibility, participation: group.participation } },
      privacy: include_private ? "includes private content at Owner request" : "excludes member-only posts, Couple Inbox conversations, contact details, credentials, and invitation codes",
      posts: posts.map { |post| { space: post.space, title: post.title, body: post.body, author: post.user.display_name, published_at: post.published_at, comments: post.comments.visible.map { |comment| { author: comment.user.display_name, body: comment.body, created_at: comment.created_at } } } },
      media: media.map(&:export_metadata)
    }
  end

  def self.content_counts_for(site)
    { posts: site.posts.count, comments: Comment.joins(:post).where(posts: { site_id: site.id }).count, events: site.events.count, groups: site.groups.count, media_assets: site.media_assets.count, approved_media_assets: site.media_assets.approved.count }
  end

  def self.checksum_for(public_payload:, private_payload:)
    Digest::SHA256.hexdigest(JSON.generate(manifest_version: MANIFEST_VERSION, public_payload:, private_payload:))
  end

  def self.published_posts_for(site, include_private:)
    posts = site.posts.visible.includes(:user, comments: :user).order(:published_at)
    return posts if include_private

    posts.where(visibility: :everyone)
         .where.not(space: :couple_inbox)
         .left_joins(:group)
         .where("posts.group_id IS NULL OR groups.visibility = ?", Group.visibilities.fetch("site_wide"))
  end
end
