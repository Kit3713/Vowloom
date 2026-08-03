require "test_helper"
require "stringio"
require "vips"
require "zip"

class AlbumExportTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = create_user("Owner", :owner)
    @member = create_user("Member", :member)
    @album = @site.albums.create!(title: "Reception photographs", visibility: :everyone, created_by: @owner)
    @public_asset = create_asset(post: @site.posts.create!(user: @owner, space: :general, visibility: :everyone, body: "Public photo", published_at: Time.current), filename: "public photo.jpg")
    @album.media_assets << @public_asset
  end

  test "a member receives an asynchronous ZIP with only media visible to them" do
    private_group = @site.groups.create!(name: "Family", visibility: :private_group, participation: :discussion, created_by: @owner)
    private_group.members << @owner
    private_asset = create_asset(post: @site.posts.create!(user: @owner, group: private_group, space: :group_space, visibility: :members_only, body: "Private photo", published_at: Time.current), filename: "private photo.jpg")
    @album.media_assets << private_asset
    sign_in(@member)

    assert_enqueued_with(job: AlbumZipExportJob) do
      post album_album_exports_path(@album)
    end
    export = @album.album_exports.last
    assert_predicate export, :queued?
    assert_not_predicate export, :include_originals?

    AlbumZipExportJob.perform_now(export)
    assert_predicate export.reload, :ready?
    assert_equal [ @public_asset.id ], export.media_asset_ids

    get download_album_album_export_path(@album, export)

    assert_response :success
    assert_equal "application/zip", response.media_type
    zip = Zip::File.open_buffer(StringIO.new(response.body))
    names = zip.entries.map(&:name)
    zip.close
    assert_equal [ "001-public_photo.jpg", "README.txt" ], names
    assert_not_includes response.body, "Private photo"
  end

  test "a completed ZIP is rejected if a source becomes private before download" do
    sign_in(@member)
    post album_album_exports_path(@album)
    export = @album.album_exports.last
    AlbumZipExportJob.perform_now(export)

    private_group = @site.groups.create!(name: "Family", visibility: :private_group, participation: :discussion, created_by: @owner)
    private_group.members << @owner
    @public_asset.post.update!(group: private_group, space: :group_space, visibility: :members_only)

    get download_album_album_export_path(@album, export)

    assert_redirected_to gallery_path
    follow_redirect!
    assert_select ".flash-alert", text: "That album download is not available to you."
  end

  test "a changed source visibility is checked again by the queued job" do
    sign_in(@member)
    post album_album_exports_path(@album)
    export = @album.album_exports.last

    private_group = @site.groups.create!(name: "Family", visibility: :private_group, participation: :discussion, created_by: @owner)
    private_group.members << @owner
    @public_asset.post.update!(group: private_group, space: :group_space, visibility: :members_only)
    AlbumZipExportJob.perform_now(export)

    assert_predicate export.reload, :failed?
    assert_not_predicate export.archive, :attached?
    assert_equal "This album has no media you can download.", export.error_message
  end

  test "a ZIP is rejected when a media record was removed after it was generated" do
    sign_in(@member)
    post album_album_exports_path(@album)
    export = @album.album_exports.last
    AlbumZipExportJob.perform_now(export)
    @public_asset.destroy!

    get download_album_album_export_path(@album, export)

    assert_redirected_to gallery_path
    follow_redirect!
    assert_select ".flash-alert", text: "That album download is not available to you."
  end

  test "only staff can request original files" do
    sign_in(@member)
    post album_album_exports_path(@album), params: { include_originals: "1" }
    assert_not_predicate @album.album_exports.last, :include_originals?

    delete session_path
    sign_in(@owner)
    post album_album_exports_path(@album), params: { include_originals: "1" }

    assert_predicate @album.album_exports.last, :include_originals?
  end

  test "expired ZIPs are purged by the scheduled cleanup job" do
    export = @album.album_exports.create!(requested_by: @member, expires_at: 1.minute.ago, status: :ready)
    export.archive.attach(io: StringIO.new("temporary archive"), filename: "temporary.zip", content_type: "application/zip")

    assert_difference "AlbumExport.count", -1 do
      PurgeExpiredAlbumExportsJob.perform_now
    end
    assert_not ActiveStorage::Attachment.exists?(record: export, name: "archive")
  end

  private

  def create_user(name, role)
    @site.users.create!(display_name: name, login_identifier: "#{name.downcase}-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role:)
  end

  def create_asset(post:, filename:)
    asset = post.media_assets.build(site: @site, user: @owner, status: :approved)
    image = Vips::Image.black(1_600, 1_200).new_from_image([ 106, 142, 185 ])
    asset.file.attach(io: StringIO.new(image.write_to_buffer(".jpg")), filename:, content_type: "image/jpeg")
    asset.save!
    asset
  end

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
