require "test_helper"

class ArchiveExportTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = create_user("Owner", :owner)
    @member = create_user("Member", :member)
    @site.posts.create!(user: @owner, space: :main, body: "Welcome", published_at: Time.current)
    @site.posts.create!(user: @owner, space: :couple_inbox, visibility: :members_only, body: "Private question", published_at: Time.current)
    @snapshot = ArchiveSnapshot.capture!(site: @site, actor: @owner)
  end

  test "owner downloads a standalone public-safe readable archive" do
    sign_in(@owner)

    get readable_export_archive_snapshot_path(@snapshot)

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_includes response.headers.fetch("Content-Disposition"), "attachment"
    assert_includes response.body, "<!doctype html>"
    assert_includes response.body, "Welcome"
    assert_not_includes response.body, "Private question"
  end

  test "only the owner can download readable archives" do
    sign_in(@member)

    get readable_export_archive_snapshot_path(@snapshot)

    assert_redirected_to community_path
  end

  test "readable public archive renders stored original media metadata" do
    post = @site.posts.create!(user: @owner, space: :main, visibility: :everyone, body: "A photo", published_at: Time.current)
    media = post.media_assets.build(site: @site, user: @owner, status: :approved, caption: "First dance")
    media.file.attach(fixture_file_upload("photo.jpg", "image/jpeg"))
    media.save!
    snapshot = ArchiveSnapshot.capture!(site: @site, actor: @owner)
    sign_in(@owner)

    get readable_export_archive_snapshot_path(snapshot)

    assert_response :success
    assert_includes response.body, "photo.jpg"
    assert_includes response.body, "First dance"
  end

  private

  def create_user(name, role)
    @site.users.create!(display_name: name, login_identifier: "#{name.downcase}-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role:)
  end

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
