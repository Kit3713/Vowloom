require "test_helper"

class QuestionnaireResponseTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @questionnaire = @site.questionnaires.create!(title: "Travel", created_by: @member, status: :published)
    @needs_ride = @questionnaire.questions.create!(position: 1, kind: :yes_no, prompt: "Need a ride?", required: true)
    @pickup_location = @questionnaire.questions.create!(position: 2, kind: :short_text, prompt: "Pickup location", conditional_rule: { "question_id" => @needs_ride.id, "equals" => "yes" })
    post session_path, params: { login_identifier: @member.login_identifier, password: "password123" }
  end

  test "conditional answers are saved only when their preceding answer enables them" do
    get questionnaire_path(@questionnaire)

    assert_response :success
    assert_select "select[name='answers[#{@needs_ride.id}]']"
    assert_select "input[name='answers[#{@pickup_location.id}]']", count: 0

    post questionnaire_response_path(@questionnaire), params: { answers: { @needs_ride.id => "yes", @pickup_location.id => "Hotel" } }

    response = @questionnaire.responses.find_by!(user: @member)
    assert_equal "Hotel", response.answers.find_by!(question: @pickup_location).value.fetch("answer")

    post questionnaire_response_path(@questionnaire), params: { answers: { @needs_ride.id => "no", @pickup_location.id => "Should be removed" } }

    assert_not response.answers.exists?(question: @pickup_location)
  end
end
