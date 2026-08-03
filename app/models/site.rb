class Site < ApplicationRecord
  class OwnershipTransferError < StandardError; end

  has_one_attached :banner_image
  has_many :users, dependent: :restrict_with_exception
  has_many :households, dependent: :destroy
  has_many :invitees, dependent: :destroy
  has_many :invitation_codes, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :questionnaires, dependent: :destroy
  has_many :registry_collections, dependent: :destroy
  has_many :albums, dependent: :destroy
  has_many :album_exports, through: :albums
  has_many :media_assets, dependent: :destroy
  has_many :kiosk_displays, dependent: :destroy
  has_many :archive_snapshots, dependent: :destroy
  has_many :moderation_reports, dependent: :destroy
  has_many :audit_events, dependent: :destroy

  enum :access_policy, { public_access: 0, private_access: 1 }, default: :public_access
  enum :content_state, { live: 0, frozen: 1 }, prefix: :content, default: :live

  validates :name, presence: true, length: { maximum: 120 }
  validates :accent_color, format: { with: /\A#[0-9a-fA-F]{6}\z/ }
  validates :media_quota_bytes, numericality: { only_integer: true, greater_than: 0 }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validate :banner_image_is_suitable

  def media_bytes_used(excluding: nil)
    assets = media_assets
    assets = assets.where.not(id: excluding.id) if excluding&.persisted?
    ActiveStorage::Attachment.where(record_type: "MediaAsset", name: "file", record_id: assets.select(:id)).joins(:blob).sum("active_storage_blobs.byte_size")
  end

  def media_quota_gigabytes
    (media_quota_bytes.to_f / 1.gigabyte).round(2)
  end

  def media_quota_gigabytes=(gigabytes)
    return if gigabytes.blank?

    self.media_quota_bytes = (gigabytes.to_d * 1.gigabyte).round
  end

  # A site row lock serializes transfers. Locking the two user rows as well
  # keeps the role changes and their audit trail in the same transaction.
  def transfer_ownership!(from:, to:)
    raise OwnershipTransferError, "A different site user must be selected." if from.id == to.id

    transaction do
      lock!
      current_owner = users.lock.find_by!(role: :owner)
      raise OwnershipTransferError, "Ownership has already changed." unless current_owner.id == from.id

      new_owner = users.lock.find(to.id)
      raise OwnershipTransferError, "The selected user already owns this site." if new_owner.owner?

      current_owner.update!(role: :admin)
      new_owner.update!(role: :owner)
      audit_events.create!(
        actor: current_owner,
        action: "site.ownership_transferred",
        auditable: new_owner,
        metadata: {
          previous_owner_id: current_owner.id,
          new_owner_id: new_owner.id,
          previous_owner_role: "admin"
        }
      )

      [ current_owner, new_owner ]
    end
  rescue ActiveRecord::RecordNotFound
    raise OwnershipTransferError, "The selected user belongs to a different site."
  end

  private

  def banner_image_is_suitable
    return unless banner_image.attached?
    return if banner_image.content_type.in?(%w[image/png image/jpeg image/webp image/gif]) && banner_image.byte_size <= 20.megabytes

    errors.add(:banner_image, "must be a PNG, JPEG, WebP, or GIF no larger than 20 MB")
  end
end
