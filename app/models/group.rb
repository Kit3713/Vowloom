class Group < ApplicationRecord
  belongs_to :site
  belongs_to :created_by, class_name: "User"
  belongs_to :event, optional: true
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :posts, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :group_resources, -> { order(:position, :created_at) }, dependent: :destroy
  has_many :questionnaires, dependent: :nullify

  enum :visibility, { site_wide: 0, private_group: 1 }, default: :site_wide
  enum :participation, { information: 0, discussion: 1 }, default: :information

  validates :name, presence: true, length: { maximum: 120 }
  validate :event_belongs_to_site

  def accessible_to?(user)
    site_wide? || user&.owner? || user&.admin? || members.include?(user)
  end

  def accepts_member_posts?
    discussion?
  end

  private

  def event_belongs_to_site
    return unless event && site
    return if event.site_id == site_id

    errors.add(:event, "must belong to this wedding site")
  end
end
