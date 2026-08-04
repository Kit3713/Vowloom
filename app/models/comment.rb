class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true, inverse_of: :replies
  has_many :replies, -> { visible }, class_name: "Comment", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :media_assets, dependent: :destroy

  scope :visible, -> { where(hidden_at: nil).order(:created_at) }
  scope :roots, -> { where(parent_id: nil) }

  validates :body, length: { maximum: 5_000 }
  validate :body_or_media_present
  validate :user_belongs_to_post_site
  validate :parent_belongs_to_same_post

  def reply?
    parent_id.present?
  end

  private

  def body_or_media_present
    errors.add(:base, "Write a message or attach a photo or video") if body.blank? && media_assets.empty?
  end

  def user_belongs_to_post_site
    errors.add(:user, "must belong to the wedding site") if user && post && user.site_id != post.site_id
  end

  def parent_belongs_to_same_post
    errors.add(:parent, "must belong to the same post") if parent && post && parent.post_id != post_id
  end
end
