require "test_helper"

class ComposablePostBlocksTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Sam and Riley", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Sam", login_identifier: "sam-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @member = @site.users.create!(display_name: "Taylor", login_identifier: "taylor-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @post = @site.posts.create!(user: @owner, space: :main, visibility: :members_only, title: "Reception setup", body: "Let us build the plan together.", published_at: Time.current)
    sign_in(@owner)
  end

  test "staff compose a post from independently interactive sticky notes" do
    assert_difference "PostBlock.count", 3 do
      create_block("note", title: "Shared notes", body: "Add useful details", interactive: "1")
      create_block("sheet", title: "Supply grid", interactive: "1")
      create_block("list", title: "Setup list", options_text: "Hang lights\nSet tables", interactive: "1")
    end

    note, sheet, list = @post.post_blocks.reload
    assert_predicate note, :interactive?
    assert_equal 2, list.list_items.length

    delete session_path
    sign_in(@member)

    patch post_post_block_path(@post, note), params: { post_block: { body: "Taylor added the loading-door instructions.", lock_version: note.lock_version } }
    assert_equal "Taylor added the loading-door instructions.", note.reload.body

    patch post_post_block_path(@post, sheet), params: { post_block: { grid_json: [ [ "Item", "Owner" ], [ "Flowers", "Taylor" ] ].to_json, lock_version: sheet.lock_version } }
    assert_equal [ "Flowers", "Taylor" ], sheet.reload.grid.second

    items = list.list_items
    items.first["done"] = true
    patch post_post_block_path(@post, list), params: { post_block: { items_json: items.to_json, lock_version: list.lock_version } }
    assert list.reload.list_items.first["done"]

    get feed_path("main")
    assert_response :success
    assert_select ".planning-block-note textarea", text: /Taylor added/
    assert_select ".planning-block-sheet table"
    assert_select ".planning-block-list input[type='checkbox'][checked]"
  end

  test "display-only notes reject member edits" do
    create_block("note", title: "Couple note", body: "The ceremony begins at four.", interactive: "0")
    note = @post.post_blocks.last
    delete session_path
    sign_in(@member)

    patch post_post_block_path(@post, note), params: { post_block: { body: "Changed", lock_version: note.lock_version } }

    assert_redirected_to feed_path("main")
    assert_equal "The ceremony begins at four.", note.reload.body
  end

  test "office-style resources remain downloadable files" do
    assert_difference "PostBlock.count", 1 do
      post post_post_blocks_path(@post), params: {
        post_block: {
          kind: "file_resource",
          title: "Guest planning sheet",
          files: [ fixture_file_upload("guests.csv", "text/csv") ]
        }
      }
    end

    block = @post.post_blocks.last
    assert_predicate block.files, :attached?
    get feed_path("main")
    assert_response :success
    assert_select ".resource-file", text: /guests.csv/
  end

  test "a post is published from mixed ordered elements instead of a post type" do
    assert_difference "Post.count", 1 do
      assert_difference "PostBlock.count", 4 do
        post posts_path, params: {
          post: {
            space: "main",
            visibility: "everyone",
            post_blocks_attributes: {
              "1" => { kind: "text", body: "Welcome to the plan 🥂" },
              "2" => { kind: "note", title: "Shared ideas", body: "Add suggestions", interactive: "1" },
              "3" => { kind: "list", title: "Setup", options_text: "Lights\nTables", interactive: "1" },
              "4" => { kind: "file_resource", title: "Guest data", files: [ fixture_file_upload("guests.csv", "text/csv") ] }
            }
          }
        }
      end
    end

    created = @site.posts.order(:created_at).last
    assert_redirected_to feed_path("main")
    assert_equal %w[text note list file_resource], created.post_blocks.pluck(:kind)
    assert_equal "Welcome to the plan 🥂", created.post_blocks.first.body
    assert_predicate created.post_blocks.second, :interactive?
    assert_equal %w[Lights Tables], created.post_blocks.third.list_items.pluck("text")
    assert_predicate created.post_blocks.fourth.files, :attached?
  end

  test "the composer exposes elements directly and relies on keyboard emoji" do
    get feed_path("main")

    assert_response :success
    assert_select ".post-type-tabs", count: 0
    assert_select "[data-post-element-canvas] [data-post-element]", count: 1
    assert_select "[data-add-post-element='note']", text: /Sticky note/
    assert_select "[data-add-post-element='sheet']", text: /Sticky sheet/
    assert_select "[data-add-post-element='list']", text: /Sticky list/
    assert_select "[data-add-post-element='file_resource']", text: /File/
    assert_select "[data-insert-emoji]", count: 0
  end

  private

  def create_block(kind, attributes = {})
    post post_post_blocks_path(@post), params: { post_block: { kind:, **attributes } }
  end

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
