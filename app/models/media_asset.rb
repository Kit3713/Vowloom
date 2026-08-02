class MediaAsset < ApplicationRecord
  belongs_to :site
  belongs_to :user
  belongs_to :post, optional: true
  belongs_to :event, optional: true
  has_many :album_items, dependent: :destroy
  has_many :albums, through: :album_items
  has_one_attached :file

  enum :status, { submitted: 0, approved: 1, hidden: 2 }, default: :submitted

  validate :file_is_supported
  validate :file_size_within_limit
  validate :file_fits_site_quota

  def image?
    file.image?
  end

  def video?
    file.video?
  end

  def export_metadata
    {
      filename: file.filename.to_s,
      content_type: file.blob.content_type,
      byte_size: file.blob.byte_size,
      checksum: file.blob.checksum,
      caption: caption,
      credit: credit,
      uploaded_by: user.display_name,
      uploaded_at: created_at
    }
  end

  private

  def file_size_within_limit
    errors.add(:file, "must be 500 MB or smaller") if file.attached? && file.byte_size > 500.megabytes
  end

  def file_fits_site_quota
    return unless file.attached? && site
    return if site.media_bytes_used(excluding: self) + file.byte_size <= site.media_quota_bytes

    errors.add(:file, "would exceed this wedding site's #{site.media_quota_gigabytes} GB media quota")
  end

  def file_is_supported
    return errors.add(:file, "must be attached") unless file.attached?
    return if file.content_type.in?([ "image/png", "image/jpeg", "image/webp", "image/gif", "video/mp4", "video/webm", "video/quicktime" ])

    errors.add(:file, "must be an image or supported video")
  end
end
