class Site < ApplicationRecord
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
end
