class User < ApplicationRecord
  has_secure_password
  has_one_attached :profile_photo
  has_many :sessions, dependent: :destroy

  normalizes :login_identifier, with: ->(value) { value.strip.downcase }
  normalizes :recovery_email, with: ->(value) { value.presence&.strip&.downcase }

  enum :role, { owner: 0, admin: 1, helper: 2, member: 3 }, default: :member

  belongs_to :site
  belongs_to :invitee, optional: true
  has_many :posts, dependent: :restrict_with_exception
  has_many :comments, dependent: :restrict_with_exception
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :audit_events, foreign_key: :actor_id, dependent: :restrict_with_exception

  validates :display_name, presence: true, length: { maximum: 80 }
  validate :profile_photo_is_an_image

  private

  def profile_photo_is_an_image
    return unless profile_photo.attached?
    return if profile_photo.content_type.in?([ "image/png", "image/jpeg", "image/webp", "image/gif" ]) && profile_photo.byte_size <= 10.megabytes

    errors.add(:profile_photo, "must be an image no larger than 10 MB")
  end
end
