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

  test "a questionnaire aimed at a person cannot be opened or answered by another member" do
    household = @site.households.create!(name: "Target household")
    intended_invitee = @site.invitees.create!(first_name: "Intended", last_name: "Guest", household:)
    unrelated_invitee = @site.invitees.create!(first_name: "Unrelated", last_name: "Guest")
    intended_member = @site.users.create!(display_name: "Intended", login_identifier: "intended-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", invitee: intended_invitee)
    @member.update!(invitee: unrelated_invitee)
    questionnaire = @site.questionnaires.create!(title: "Arrival details", created_by: @owner, status: :published)
    questionnaire.audience_targets.create!(invitee: intended_invitee)
    question = questionnaire.questions.create!(position: 1, kind: :short_text, prompt: "When do you arrive?", required: true)

    sign_in(@member)
    get questionnaire_path(questionnaire)
    assert_redirected_to questionnaires_path

    assert_no_difference "QuestionnaireResponse.count" do
      post questionnaire_response_path(questionnaire), params: { answers: { question.id => "Friday" } }
    end
    assert_equal "This questionnaire is not available to you.", flash[:alert]

    delete session_path
    sign_in(intended_member)
    assert_difference "QuestionnaireResponse.count", 1 do
      post questionnaire_response_path(questionnaire), params: { answers: { question.id => "Friday" } }
    end
  end

  test "a household-targeted questionnaire is available to each linked household member" do
    household = @site.households.create!(name: "Family")
    first_invitee = @site.invitees.create!(first_name: "First", last_name: "Family", household:)
    second_invitee = @site.invitees.create!(first_name: "Second", last_name: "Family", household:)
    first_member = @site.users.create!(display_name: "First", login_identifier: "first-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", invitee: first_invitee)
    second_member = @site.users.create!(display_name: "Second", login_identifier: "second-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", invitee: second_invitee)
    questionnaire = @site.questionnaires.create!(title: "Household travel", created_by: @owner, status: :published, response_scope: :household)
    questionnaire.audience_targets.create!(household:)
    question = questionnaire.questions.create!(position: 1, kind: :short_text, prompt: "Travel plan", required: true)

    sign_in(first_member)
    assert_difference "QuestionnaireResponse.count", 1 do
      post questionnaire_response_path(questionnaire), params: { answers: { question.id => "Driving" } }
    end

    delete session_path
    sign_in(second_member)
    get questionnaire_path(questionnaire)
    assert_response :success
    assert_select "h1", text: "Household travel"
  end

  test "staff entry cannot be used to submit for someone outside a selected audience" do
    intended_invitee = @site.invitees.create!(first_name: "Intended", last_name: "Guest")
    unrelated_invitee = @site.invitees.create!(first_name: "Unrelated", last_name: "Guest")
    questionnaire = @site.questionnaires.create!(title: "Arrival details", created_by: @owner, status: :published)
    questionnaire.audience_targets.create!(invitee: intended_invitee)
    question = questionnaire.questions.create!(position: 1, kind: :short_text, prompt: "When do you arrive?", required: true)
    sign_in(@owner)

    assert_no_difference "QuestionnaireResponse.count" do
      post questionnaire_response_path(questionnaire), params: {
        staff_invitee_id: unrelated_invitee.id,
        answers: { question.id => "Friday" }
      }
    end

    assert_equal "Choose an invited person included in this questionnaire's audience.", flash[:alert]
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
