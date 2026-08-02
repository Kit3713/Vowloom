require "test_helper"

class ArchiveSearchTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a", content_state: :frozen)
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @site.posts.create!(user: @owner, space: :main, title: "Ceremony", body: "The lanterns looked beautiful.", published_at: Time.current)
    @site.posts.create!(user: @owner, space: :couple_inbox, visibility: :members_only, body: "Private lantern discussion.", published_at: Time.current)
  end

  test "public frozen archives search public posts but not private conversations" do
    get archive_search_path(q: "lantern")

    assert_response :success
    assert_select "h2", text: "Ceremony"
    assert_select "body", text: /Private lantern discussion/, count: 0
  end

  test "private frozen archives require sign-in before searching" do
    @site.update!(access_policy: :private_access)

    get archive_search_path(q: "lantern")

    assert_redirected_to new_session_path
  end
end
