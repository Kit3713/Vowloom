require "test_helper"

class GroupPostUploadTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @group = @site.groups.create!(name: "Wedding party", participation: :discussion, created_by: @member)
    @group.members << @member
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }
  end

  test "member can post an upload and comment in a discussion group" do
    get group_path(@group)

    assert_response :success
    assert_select "input[type=file][name^='post[post_blocks_attributes]'][name$='[files][]']"

    upload = fixture_file_upload("photo.jpg", "image/jpeg")

    assert_difference "Post.count", 1 do
      assert_difference "PostBlock.count", 2 do
        assert_difference "MediaAsset.count", 1 do
          post posts_path, params: { post: { space: "group_space", group_id: @group.id, post_blocks_attributes: {
            "1" => { kind: "text", body: "For the group" },
            "2" => { kind: "media", files: [ upload ] }
          } } }
        end
      end
    end

    assert_redirected_to group_path(@group)
    group_post = @group.posts.last
    assert_equal %w[text media], group_post.post_blocks.pluck(:kind)
    assert_predicate group_post.post_blocks.last.media_assets.first.file, :attached?

    assert_difference "Comment.count", 1 do
      post post_comments_path(group_post), params: { comment: { body: "Looks great!" } }
    end

    assert_redirected_to group_path(@group)

    assert_difference "Task.count", 1 do
      post group_tasks_path(@group), params: { task: { title: "Bring flowers" } }
    end

    task = @group.tasks.last
    assert_difference "TaskComment.count", 1 do
      post group_task_task_comments_path(@group, task), params: { task_comment: { body: "I can handle this." } }
    end

    assert_redirected_to group_path(@group)
  end
end
