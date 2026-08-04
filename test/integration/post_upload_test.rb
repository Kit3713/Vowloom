require "test_helper"

class PostUploadTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }
  end

  test "member post keeps an uploaded photo in its source context" do
    upload = fixture_file_upload("photo.jpg", "image/jpeg")

    assert_difference "Post.count", 1 do
      assert_difference "PostBlock.count", 2 do
        assert_difference "MediaAsset.count", 1 do
          post posts_path, params: { post: { space: "general", visibility: "members_only", post_blocks_attributes: {
            "1" => { kind: "text", body: "A moment from the weekend" },
            "2" => { kind: "media", files: [ upload ] }
          } } }
        end
      end
    end

    assert_redirected_to feed_path("general")
    post = @site.posts.order(:created_at).last
    assert_equal %w[text media], post.post_blocks.pluck(:kind)
    assert_predicate post.post_blocks.last.media_assets.first.file, :attached?
    assert_predicate post.post_blocks.last.media_assets.first, :submitted?
  end
end
