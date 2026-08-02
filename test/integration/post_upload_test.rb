require "test_helper"

class PostUploadTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }
  end

  test "member post keeps an uploaded photo in its source context" do
    upload = fixture_file_upload("photo.jpg", "image/jpeg")

    assert_difference [ "Post.count", "MediaAsset.count" ], 1 do
      post posts_path, params: { post: { space: "general", body: "A moment from the weekend", visibility: "members_only", files: [ upload ] } }
    end

    assert_redirected_to feed_path("general")
    post = @site.posts.order(:created_at).last
    assert_equal post, @site.media_assets.last.post
    assert_predicate @site.media_assets.last, :submitted?
  end
end
