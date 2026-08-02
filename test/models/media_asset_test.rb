require "test_helper"
require "stringio"

class MediaAssetTest < ActiveSupport::TestCase
  test "uploads are rejected when they exceed the wedding media quota" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a", media_quota_bytes: 1.megabyte)
    user = site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    asset = site.media_assets.build(user:)
    attach_photo(asset)
    site.update_column(:media_quota_bytes, asset.file.byte_size - 1)
    site.reload

    assert_not_predicate asset, :valid?
    assert_includes asset.errors[:file], "would exceed this wedding site's 0.0 GB media quota"
  end

  test "media usage sums files attached to this wedding site" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    user = site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    asset = site.media_assets.build(user:)
    attach_photo(asset)
    asset.save!

    assert_equal asset.file.byte_size, site.media_bytes_used
  end

  private

  def attach_photo(asset)
    asset.file.attach(io: StringIO.new(File.binread(Rails.root.join("test/fixtures/files/photo.jpg"))), filename: "photo.jpg", content_type: "image/jpeg")
  end
end
