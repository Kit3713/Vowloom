class Album < ApplicationRecord
  belongs_to :site
  belongs_to :created_by, class_name: "User"
  belongs_to :event, optional: true
  has_many :album_items, dependent: :destroy
  has_many :media_assets, through: :album_items
  has_many :album_exports, dependent: :destroy
  has_many :group_resources, as: :resourceable, dependent: :destroy

  enum :visibility, { everyone: 0, members_only: 1 }, default: :members_only
  validates :title, presence: true, length: { maximum: 180 }

  def accessible_to?(viewer)
    everyone? || viewer&.site_id == site_id
  end

  # Gallery promotion must never make a source post more widely accessible.
  # Export jobs use this method both when queued and when they run, so a private
  # group image cannot escape through a broadly visible album.
  def exportable_media_assets_for(viewer)
    media_assets.approved.with_attached_file.order(:created_at).select { |asset| asset.accessible_to?(viewer) }
  end
end
