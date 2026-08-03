class AlbumExport < ApplicationRecord
  DOWNLOAD_LIFETIME = 7.days

  belongs_to :album
  belongs_to :requested_by, class_name: "User"
  has_one_attached :archive

  enum :status, { queued: 0, processing: 1, ready: 2, failed: 3 }, default: :queued

  validates :expires_at, presence: true
  validate :requester_belongs_to_album_site

  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def downloadable_by?(viewer)
    return false unless ready? && archive.attached? && !expired?
    return false unless viewer && viewer.site_id == album.site_id
    return false unless viewer == requested_by || viewer.owner? || viewer.admin?
    return false if include_originals? && !staff?(viewer)

    ids = media_asset_ids.map(&:to_i).uniq
    return false if ids.empty?

    assets = album.media_assets.where(id: ids).to_a
    return false unless assets.length == ids.length

    assets.all? do |asset|
      asset.approved? && asset.accessible_to?(viewer)
    end
  end

  def expired?
    expires_at <= Time.current
  end

  def self.purge_expired!(site)
    site.album_exports.expired.find_each do |export|
      export.archive.purge if export.archive.attached?
      export.destroy!
    end
  end

  private

  def requester_belongs_to_album_site
    return if requested_by.blank? || album.blank? || requested_by.site_id == album.site_id

    errors.add(:requested_by, "must belong to the same wedding site as the album")
  end

  def staff?(user)
    user.owner? || user.admin? || user.helper?
  end
end
