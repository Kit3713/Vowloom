class PurgeExpiredAlbumExportsJob < ApplicationJob
  queue_as :maintenance

  def perform
    AlbumExport.expired.find_each do |export|
      export.archive.purge if export.archive.attached?
      export.destroy!
    end
  end
end
