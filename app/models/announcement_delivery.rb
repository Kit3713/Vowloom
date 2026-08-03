class AnnouncementDelivery < ApplicationRecord
  belongs_to :post
  belongs_to :recipient, class_name: "User"

  enum :status, { pending: 0, sending: 1, delivered: 2, cancelled: 3, failed: 4 }, default: :pending

  validates :recipient_id, uniqueness: { scope: :post_id }
  validate :recipient_belongs_to_the_post_site

  private

  def recipient_belongs_to_the_post_site
    return unless post && recipient
    return if post.site_id == recipient.site_id

    errors.add(:recipient, "must belong to the same wedding site as the announcement")
  end
end
