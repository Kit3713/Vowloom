class AlbumItem < ApplicationRecord
  belongs_to :album
  belongs_to :media_asset
  validates :media_asset_id, uniqueness: { scope: :album_id }
end
