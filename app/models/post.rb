class Post < ApplicationRecord
  belongs_to :site
  belongs_to :user
  belongs_to :group, optional: true
  belongs_to :event, optional: true
  belongs_to :postable, polymorphic: true, optional: true
  has_many :comments, dependent: :destroy
  has_many :media_assets, dependent: :nullify

  enum :space, { main: 0, general: 1, group_space: 2, couple_inbox: 3 }, default: :main
  enum :visibility, { everyone: 0, members_only: 1 }, default: :everyone

  scope :visible, -> { where(hidden_at: nil).where.not(published_at: nil) }
  scope :chronological, -> { order(pinned: :desc, published_at: :desc) }

  validates :body, presence: true, length: { maximum: 10_000 }
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

    true
  end

  private

  def group_space_has_group
    errors.add(:group, "is required for a group post") if group_space? && group.blank?
  end

  def user_belongs_to_site
    errors.add(:user, "must belong to this wedding site") if user && site && user.site_id != site_id
  end
end
