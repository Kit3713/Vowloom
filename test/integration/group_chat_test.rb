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

  test "a group manager opens a real-time group conversation for group members" do
    assert_difference "Post.count", 1 do
      post group_chat_path(@group)
    end

    conversation = @group.posts.find_by!(conversation: true)
    assert_redirected_to group_chat_path(@group)
    assert_predicate conversation, :group_space?
    assert_equal @group, conversation.group

    delete session_path
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }
    get group_chat_path(@group)

    assert_response :success
    assert_select "h1", text: "Wedding party chat"
    assert_select "turbo-cable-stream-source"
  end

  test "information groups cannot open chat or accept member replies from stale chats" do
    information_group = @site.groups.create!(name: "Travel details", participation: :information, created_by: @owner)
    information_group.members << @member

    assert_no_difference "Post.count" do
      post group_chat_path(information_group)
    end
    assert_redirected_to group_path(information_group)
    assert_equal "Only discussion groups can open a live chat.", flash[:alert]

    stale_conversation = information_group.posts.create!(site: @site, user: @owner, space: :group_space, visibility: :everyone, title: "Old chat", body: "Previously opened", comments_enabled: true, conversation: true, published_at: Time.current)

    delete session_path
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }
    get group_chat_path(information_group)
    assert_redirected_to group_path(information_group)
    assert_equal "This information group does not use member chat.", flash[:alert]

    assert_no_difference "Comment.count" do
      post post_comments_path(stale_conversation), params: { comment: { body: "Can I reply?" } }
    end
    assert_redirected_to group_path(information_group)
    assert_equal "You cannot reply to that conversation.", flash[:alert]
  end

  test "feed navigation points to the event, gallery, and group pages" do
    get feed_path("main")

    assert_response :success
    assert_select "a[href='#{events_path}']", text: "Events"
    assert_select "a[href='#{gallery_path}']", text: "Gallery"
    assert_select "a[href='#{groups_path}']", text: "Groups"
  end
end
