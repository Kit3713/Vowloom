class MediaAsset < ApplicationRecord
  # Keep these intentionally small and named.  Views must not choose their own
  # transformations: every browser-facing image is a bounded, metadata-stripped
  # derivative, while the Active Storage blob remains the unmodified original.
  IMAGE_RENDITIONS = {
    thumbnail: {
      resize_to_fill: [ 360, 360 ],
      format: :webp,
      saver: { strip: true, quality: 76, effort: 4 }
    },
    feed: {
      resize_to_limit: [ 1_280, 1_280 ],
      format: :webp,
      saver: { strip: true, quality: 82, effort: 4 }
    },
    fullscreen: {
      resize_to_limit: [ 2_560, 1_920 ],
      format: :webp,
      saver: { strip: true, quality: 86, effort: 4 }
    },
    web_download: {
      resize_to_limit: [ 2_000, 2_000 ],
      format: :jpeg,
      saver: { strip: true, quality: 88, optimize_coding: true, interlace: true }
    }
  }.freeze

  belongs_to :site
  belongs_to :user
  belongs_to :post, optional: true
  belongs_to :event, optional: true
  has_many :album_items, dependent: :destroy
  has_many :albums, through: :album_items
  has_many :group_resources, as: :resourceable, dependent: :destroy
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

  # Returns an Active Storage variant, rather than generating another managed
  # attachment. Variants are content-addressed and are regenerated on demand;
  # this keeps a high-resolution original intact for the archive and authorized
  # download while preventing a source-sized image from reaching normal pages.
  def rendition(name)
    raise ArgumentError, "image renditions are only available for images" unless image?

    file.variant(IMAGE_RENDITIONS.fetch(name.to_sym))
  end

  # A portable archive needs to identify the original even though it does not
  # contain original bytes. Blob analysis supplies safe technical fields (not
  # raw EXIF), so no location or camera metadata is copied into a public export.
  def original_metadata
    blob = file.blob
    metadata = blob.metadata

    {
      filename: blob.filename.to_s,
      content_type: blob.content_type,
      byte_size: blob.byte_size,
      checksum: blob.checksum,
      width: metadata["width"],
      height: metadata["height"],
      analyzed: blob.analyzed?
    }.compact
  end

  # Media inherits visibility from the post where it was originally shared.
  # Curating it into the Gallery never makes private group or member-only
  # content public. A hidden source post also hides every attached asset; its
  # curation flags must not turn a moderated post into a separate public copy.
  def accessible_to?(viewer)
    return false if post && !post.published?
    return true if publicly_accessible?
    return false unless viewer

    post.accessible_to?(viewer)
  end

  def publicly_accessible?
    return false if post && !post.published?
    return true unless post

    post.everyone? && (!post.group_space? || post.group.site_wide?)
  end

  def export_metadata
    {
      original: original_metadata,
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
