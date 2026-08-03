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
end
