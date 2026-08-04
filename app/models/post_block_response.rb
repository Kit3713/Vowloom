class PostBlockResponse < ApplicationRecord
  belongs_to :post_block
  belongs_to :user

  validates :submitted_at, presence: true
  validate :user_belongs_to_post_site
  validate :selections_are_allowed

  private

  def user_belongs_to_post_site
    errors.add(:user, "must belong to this wedding site") if user && post_block && user.site_id != post_block.post.site_id
  end

  def selections_are_allowed
    selections = Array(payload["selections"])
    return if selections.all? { |selection| post_block.options.include?(selection) }

    errors.add(:payload, "contains an unavailable option")
  end
end
