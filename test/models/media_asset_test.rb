require "test_helper"
require "stringio"
require "vips"

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

  test "safe Vips renditions preserve the original and bound browser copies" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    user = site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    asset = site.media_assets.build(user:)
    attach_processable_photo(asset)
    asset.save!
    asset.file.blob.analyze

    original = asset.original_metadata
    feed = asset.rendition(:feed).processed
    image = Vips::Image.new_from_buffer(feed.download, "")

    assert_equal "image/jpeg", original.fetch(:content_type)
    assert_equal asset.file.byte_size, original.fetch(:byte_size)
    assert_equal asset.file.checksum, original.fetch(:checksum)
    assert_equal "image/webp", feed.content_type
    assert_operator image.width, :<=, 1_280
    assert_operator image.height, :<=, 1_280
    assert_equal "image/jpeg", asset.file.blob.content_type
    assert_raises(KeyError) { asset.rendition(:unrecognized) }
  end

  test "only a public source context makes curated media public" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    user = site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    public_post = site.posts.create!(user:, space: :general, visibility: :everyone, body: "Public", published_at: Time.current)
    private_post = site.posts.create!(user:, space: :general, visibility: :members_only, body: "Private", published_at: Time.current)

    public_asset = public_post.media_assets.build(site:, user:)
    private_asset = private_post.media_assets.build(site:, user:)
    attach_photo(public_asset)
    attach_photo(private_asset)
    public_asset.save!
    private_asset.save!

    assert_predicate public_asset, :publicly_accessible?
    assert_not_predicate private_asset, :publicly_accessible?
    assert public_asset.accessible_to?(nil)
    assert_not private_asset.accessible_to?(nil)
  end

  private

  def attach_photo(asset)
    asset.file.attach(io: StringIO.new(File.binread(Rails.root.join("test/fixtures/files/photo.jpg"))), filename: "photo.jpg", content_type: "image/jpeg")
  end

  def attach_processable_photo(asset)
    image = Vips::Image.black(1_600, 1_200).new_from_image([ 106, 142, 185 ])
    asset.file.attach(io: StringIO.new(image.write_to_buffer(".jpg")), filename: "processable-photo.jpg", content_type: "image/jpeg")
  end
end
