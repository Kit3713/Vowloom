require "test_helper"

class InteractiveSocialPostsTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Sam and Riley", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Sam", login_identifier: "sam-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @member = @site.users.create!(display_name: "Taylor", login_identifier: "taylor-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :member)
    @post = @site.posts.create!(user: @owner, space: :general, visibility: :members_only, post_type: :discussion, title: "Wedding weekend", body: "Who is ready?", published_at: Time.current)
    sign_in(@member)
  end

  test "members add emoji, media, and a one-level threaded reply" do
    assert_difference [ "Comment.count", "MediaAsset.count" ], 1 do
      post post_comments_path(@post), params: {
        comment: {
          body: "Cannot wait! 🥂✨",
          files: [ fixture_file_upload("photo.jpg", "image/jpeg") ]
        }
      }
    end

    root_comment = @post.comments.last
    assert_equal "Cannot wait! 🥂✨", root_comment.body
    assert_equal root_comment, @site.media_assets.last.comment
    assert_equal @post, @site.media_assets.last.post

    assert_difference "Comment.count", 1 do
      post post_comments_path(@post), params: { comment: { body: "Same here ❤️", parent_id: root_comment.id } }
    end

    reply = @post.comments.last
    assert_equal root_comment, reply.parent

    assert_difference "Comment.count", 1 do
      post post_comments_path(@post), params: { comment: { body: "Nested replies stay simple", parent_id: reply.id } }
    end
    assert_equal root_comment, @post.comments.last.parent

    get feed_path("general")
    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(root_comment)} .comment-media img", count: 1
    assert_select ".comment-replies .comment-reply", minimum: 2
  end

  test "staff publish a questionnaire as an interactive Main post" do
    delete session_path
    sign_in(@owner)

    assert_difference [ "Questionnaire.count", "Post.questionnaire_post.count" ], 1 do
      post questionnaires_path, params: {
        publish_now: "1",
        publish_to_feed: "1",
        questionnaire: {
          title: "Reception meal",
          introduction: "Choose what you would like for dinner.",
          results_visibility: "staff_only"
        }
      }
    end

    questionnaire = @site.questionnaires.last
    questionnaire.questions.create!(position: 1, kind: :single_choice, prompt: "Meal choice", options: [ "Chicken", "Vegetarian" ], required: true)
    timeline_post = questionnaire.timeline_post
    assert_predicate timeline_post, :questionnaire_post?
    assert_equal questionnaire, timeline_post.postable

    get feed_path("main")
    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(timeline_post)} .questionnaire-post", text: /Reception meal/
    assert_select "form[action='#{questionnaire_response_path(questionnaire)}'] select[name='answers[#{questionnaire.questions.first.id}]']"
    assert_select ".social-nav-link", text: "Questions", count: 0
    assert_select ".social-nav-link", text: "Wedding chat", count: 0
  end

  private

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
