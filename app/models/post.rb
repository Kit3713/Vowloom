class Post < ApplicationRecord
  attr_accessor :send_important_announcement_email

  belongs_to :site
  belongs_to :user
  belongs_to :group, optional: true
  belongs_to :event, optional: true
  belongs_to :postable, polymorphic: true, optional: true
  has_many :comments, dependent: :destroy
  has_many :media_assets, dependent: :nullify
  has_many :announcement_deliveries, dependent: :destroy
  has_many :post_blocks, -> { ordered }, dependent: :destroy

  enum :space, { main: 0, general: 1, group_space: 2, couple_inbox: 3 }, default: :main
  enum :visibility, { everyone: 0, members_only: 1 }, default: :everyone
  enum :post_type, { story: 0, discussion: 1, media_post: 2, questionnaire_post: 3 }, default: :story

  scope :visible, -> { where(hidden_at: nil).where.not(published_at: nil) }
  scope :chronological, -> { order(pinned: :desc, published_at: :desc) }

  validates :body, length: { maximum: 10_000 }
  validate :body_title_or_media_present
  validate :group_space_has_group
  validate :user_belongs_to_site

  def published?
    published_at.present? && hidden_at.nil?
  end

  def accessible_to?(viewer)
    return false unless viewer
    return viewer.owner? || viewer.admin? || viewer == user if couple_inbox?
    return group.accessible_to?(viewer) if group_space?

    everyone? || viewer.site_id == site_id
  end

  def commentable_by?(viewer)
    return false unless comments_enabled? && accessible_to?(viewer)
    return viewer.owner? || viewer.admin? || viewer == user if couple_inbox?
    return viewer.owner? || viewer.admin? || viewer == user if conversation? && group_space? && group.information?

    true
  end

  def manageable_by?(viewer)
    return false unless viewer&.site_id == site_id
    return true if viewer.owner? || viewer.admin? || viewer.helper?

    viewer == user && (general? || group_space?)
  end

  def email_announcement_deliverable?
    main? && important_announcement? && announcement_email_queued_at.present? && published?
  end

  # Recipients are selected once, when an Owner or Admin publishes an
  # announcement. Each delivery row prevents a later job retry or a changed
  # guest list from silently adding more people to the notification.
  def queue_important_announcement_emails!(actor:)
    raise ArgumentError, "Only Main posts can be emailed" unless main?
    raise ArgumentError, "Only Owners and Admins can send announcement emails" unless actor.owner? || actor.admin?
    raise ArgumentError, "The actor must belong to this wedding site" unless actor.site_id == site_id

    with_lock do
      return [] if announcement_email_queued_at?

      update!(important_announcement: true, announcement_email_queued_at: Time.current)
      delivery_ids = site.users.important_announcement_recipients.find_each.filter_map do |recipient|
        announcement_deliveries.create!(recipient:).id
      end
      site.audit_events.create!(
        actor:,
        action: "announcement.email_delivery_queued",
        auditable: self,
        metadata: { recipient_count: delivery_ids.length }
      )
      delivery_ids
    end
  end

  private

  def body_title_or_media_present
    errors.add(:base, "Add at least one element to the post") if body.blank? && title.blank? && media_assets.empty? && postable.blank? && post_blocks.empty?
  end

  def group_space_has_group
    errors.add(:group, "is required for a group post") if group_space? && group.blank?
  end

  def user_belongs_to_site
    errors.add(:user, "must belong to this wedding site") if user && site && user.site_id != site_id
  end
end
