require "test_helper"

class QuestionnaireManagementTest < ActionDispatch::IntegrationTest
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @questionnaire = @site.questionnaires.create!(title: "Arrival plans", created_by: @owner, status: :published)
    @question = @questionnaire.questions.create!(position: 1, kind: :single_choice, prompt: "Arrival day", options: [ "Friday", "Saturday" ])
    sign_in(@owner)
  end

  test "staff can schedule and close a questionnaire after it has been created" do
    patch questionnaire_path(@questionnaire), params: {
      questionnaire: {
        title: "Arrival plans",
        introduction: "Please tell us when you arrive.",
        status: "closed",
        response_scope: "individual",
        results_visibility: "aggregate",
        opens_at: "2028-06-01T09:00",
        closes_at: "2028-06-05T09:00",
        group_id: "",
        event_id: ""
      }
    }

    assert_redirected_to questionnaire_path(@questionnaire)
    @questionnaire.reload
    assert_predicate @questionnaire, :closed?
    assert_equal "Please tell us when you arrive.", @questionnaire.introduction
    assert_predicate @questionnaire, :aggregate?
    assert_equal Time.zone.parse("2028-06-05 09:00"), @questionnaire.closes_at
  end

  test "answered questions retain their structure while staff can correct wording" do
    response = @questionnaire.responses.create!(user: @member, submitted_at: Time.current)
    response.answers.create!(question: @question, value: { "answer" => "Friday" })

    patch questionnaire_question_path(@questionnaire, @question), params: {
      question: { prompt: "Which day will you arrive?", kind: "long_text", options_text: "Anything" }
    }

    assert_redirected_to questionnaire_path(@questionnaire)
    @question.reload
    assert_equal "Which day will you arrive?", @question.prompt
    assert_equal "single_choice", @question.kind
    assert_equal [ "Friday", "Saturday" ], @question.options

    delete questionnaire_question_path(@questionnaire, @question)

    assert @questionnaire.questions.exists?(@question.id)
    assert_match "cannot be removed", flash[:alert]
  end

  test "audience and response scope cannot change after a response exists" do
    @questionnaire.responses.create!(user: @member, submitted_at: Time.current)

    patch questionnaire_path(@questionnaire), params: {
      questionnaire: {
        title: @questionnaire.title,
        status: "published",
        response_scope: "household",
        results_visibility: "staff_only",
        group_id: "",
        event_id: ""
      }
    }

    assert_redirected_to questionnaire_path(@questionnaire)
    assert_predicate @questionnaire.reload, :individual?
    assert_match "cannot be changed", flash[:alert]
  end

  private

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
