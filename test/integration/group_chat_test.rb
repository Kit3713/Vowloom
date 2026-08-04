require "test_helper"

class GroupChatTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @group = @site.groups.create!(name: "Wedding party", participation: :discussion, created_by: @owner)
    @group.members << @member
    post session_path, params: { login_identifier: @owner.login_identifier, password: "password123" }
  end

  test "legacy group chat routes lead to the unified group timeline" do
    assert_no_difference "Post.count" do
      post group_chat_path(@group)
    end
    assert_redirected_to group_path(@group)

    delete session_path
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }
    get group_chat_path(@group)
    assert_redirected_to group_path(@group)
  end

  test "every accessible group combines member posts and threaded discussion" do
    information_group = @site.groups.create!(name: "Travel details", participation: :information, created_by: @owner)
    information_group.members << @member
    delete session_path
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }

    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { space: "group_space", group_id: information_group.id, body: "Our flight lands Friday." } }
    end
    group_post = information_group.posts.visible.last
    assert_redirected_to group_path(information_group)

    assert_difference "Comment.count", 1 do
      post post_comments_path(group_post), params: { comment: { body: "We can share a ride." } }
    end
    assert_redirected_to group_path(information_group)
  end

  test "feed navigation points to the event, gallery, and group pages" do
    get feed_path("main")

    assert_response :success
    assert_select "a[href='#{events_path}']", text: "Events"
    assert_select "a[href='#{gallery_path}']", text: "Gallery"
    assert_select "a[href='#{groups_path}']", text: "Groups"
  end
end
