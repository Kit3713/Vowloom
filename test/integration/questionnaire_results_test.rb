require "test_helper"

class QuestionnaireResultsTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @questionnaire = @site.questionnaires.create!(title: "Song poll", created_by: @owner, status: :published, results_visibility: :aggregate)
    @question = @questionnaire.questions.create!(position: 1, kind: :single_choice, prompt: "Pick a song", options: [ "Song A", "Song B" ])
    response = @questionnaire.responses.create!(user: @member, submitted_at: Time.current)
    response.answers.create!(question: @question, value: { "answer" => "Song A" })
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }
  end

  test "aggregate questionnaires show response counts without exposing respondent identities" do
    get questionnaire_path(@questionnaire)

    assert_response :success
    assert_select ".questionnaire-results", text: /Song A: 1/
    assert_select ".questionnaire-results", text: /Member/, count: 0
  end
end
