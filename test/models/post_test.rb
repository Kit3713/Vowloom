require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @outsider = @site.users.create!(display_name: "Outsider", login_identifier: "outsider-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
  end

  test "couple inbox conversations are visible only to their member and owner/admin" do
    conversation = @site.posts.create!(user: @member, space: :couple_inbox, visibility: :members_only, title: "Question", body: "Can I help?", published_at: Time.current)

    assert conversation.accessible_to?(@member)
    assert conversation.accessible_to?(@owner)
    assert_not conversation.accessible_to?(@outsider)
    assert conversation.commentable_by?(@member)
    assert conversation.commentable_by?(@owner)
    assert_not conversation.commentable_by?(@outsider)
  end

  test "a group post requires a group" do
    post = @site.posts.build(user: @member, space: :group_space, body: "Hello", published_at: Time.current)

    assert_not post.valid?
    assert_includes post.errors[:group], "is required for a group post"
  end
end
