require "test_helper"

class PrivacyBoundariesTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = create_user("Owner", :owner)
    @member = create_user("Member", :member)
  end

  test "visitors cannot read the members-only wedding chat" do
    @site.posts.create!(user: @owner, space: :main, visibility: :members_only, title: "Wedding chat", body: "Private conversation", conversation: true, published_at: Time.current)

    get chat_path

    assert_redirected_to new_session_path
  end

  test "members cannot submit a response to a questionnaire outside their group audience" do
    group = @site.groups.create!(name: "Wedding party", visibility: :private_group, participation: :discussion, created_by: @owner)
    questionnaire = @site.questionnaires.create!(title: "Private travel", created_by: @owner, group:, status: :published)
    question = questionnaire.questions.create!(position: 1, kind: :short_text, prompt: "Arrival time", required: true)
    sign_in(@member)

    assert_no_difference "QuestionnaireResponse.count" do
      post questionnaire_response_path(questionnaire), params: { answers: { question.id => "Friday" } }
    end

    assert_redirected_to questionnaire_path(questionnaire)
    assert_equal "This questionnaire is not available to you.", flash[:alert]
  end

  test "media shared in a private group cannot be downloaded by an unrelated member" do
    group = @site.groups.create!(name: "Family", visibility: :private_group, participation: :discussion, created_by: @owner)
    group.members << @owner
    post = @site.posts.create!(site: @site, user: @owner, group:, space: :group_space, visibility: :members_only, body: "Private photo", published_at: Time.current)
    asset = post.media_assets.build(site: @site, user: @owner, status: :approved)
    asset.file.attach(fixture_file_upload("photo.jpg", "image/jpeg"))
    asset.save!
    sign_in(@member)

    get download_media_asset_path(asset)

    assert_redirected_to gallery_path
    follow_redirect!
    assert_select ".flash-alert", text: "That media is not available to you."
  end

  test "members cannot claim unpublished registry items by guessing their URL" do
    collection = @site.registry_collections.create!(title: "Draft gifts", published: false)
    item = collection.registry_items.create!(title: "Draft item", quantity_requested: 1, published: false)
    sign_in(@member)

    assert_no_difference "RegistryClaim.count" do
      post registry_item_registry_claims_path(item), params: { quantity: 1 }
    end

    assert_response :not_found
  end

  private

  def create_user(name, role)
    @site.users.create!(display_name: name, login_identifier: "#{name.downcase}-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role:)
  end

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
