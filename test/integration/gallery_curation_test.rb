require "test_helper"

class GalleryCurationTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @admin = @site.users.create!(display_name: "Admin", login_identifier: "admin-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :admin)
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @album = @site.albums.create!(title: "Reception", created_by: @admin)
    @asset = @site.media_assets.build(user: @member, caption: "Original caption")
    @asset.file.attach(fixture_file_upload("photo.jpg", "image/jpeg"))
    @asset.save!
    post session_path, params: { login_identifier: @admin.login_identifier, password: "password123" }
  end

  test "staff can approve, credit, feature, and add submitted media to an album" do
    patch media_asset_path(@asset), params: { moderation_action: "approve", album_id: @album.id, media_asset: { caption: "First dance", credit: "Pat Photographer", featured: "1" } }

    assert_redirected_to gallery_path
    @asset.reload
    assert_predicate @asset, :approved?
    assert_predicate @asset, :featured?
    assert_equal "First dance", @asset.caption
    assert_equal "Pat Photographer", @asset.credit
    assert_includes @album.media_assets, @asset
  end

  test "staff can hide a submitted upload" do
    patch media_asset_path(@asset), params: { moderation_action: "hide", media_asset: { featured: "0" } }

    assert_predicate @asset.reload, :hidden?
  end
end
