class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user

  scope :visible, -> { where(hidden_at: nil).order(:created_at) }

  validates :body, presence: true, length: { maximum: 5_000 }
  validate :user_belongs_to_post_site

  private

  def user_belongs_to_post_site
    errors.add(:user, "must belong to the wedding site") if user && post && user.site_id != post.site_id
  end
end
