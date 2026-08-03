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
        response_edit_policy: "locked_after_submission",
        response_scope: "individual",
        results_visibility: "respondent_and_staff",
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
    assert_predicate @questionnaire, :respondent_and_staff?
    assert_predicate @questionnaire, :locked_after_submission?
    assert_equal Time.zone.parse("2028-06-05 09:00"), @questionnaire.closes_at
  end

  test "answered questions retain their structure while staff can correct wording" do
    response = @questionnaire.responses.create!(user: @member, submitted_at: Time.current)
    response.answers.create!(question: @question, value: { "answer" => "Friday" })

    patch questionnaire_question_path(@questionnaire, @question), params: {
      question: { prompt: "Which day will you arrive?", section: "Travel details", kind: "long_text", options_text: "Anything" }
    }

    assert_redirected_to questionnaire_path(@questionnaire)
    @question.reload
    assert_equal "Which day will you arrive?", @question.prompt
    assert_equal "Travel details", @question.section
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

  test "staff can select people and households before answers exist" do
    household = @site.households.create!(name: "Family")
    invitee = @site.invitees.create!(first_name: "Taylor", last_name: "Guest", household:)

    patch questionnaire_path(@questionnaire), params: {
      questionnaire: {
        title: @questionnaire.title,
        status: "published",
        response_scope: "individual",
        results_visibility: "staff_only",
        group_id: "",
        event_id: "",
        targeted_invitee_ids: [ invitee.id.to_s ],
        targeted_household_ids: [ household.id.to_s ]
      }
    }

    assert_redirected_to questionnaire_path(@questionnaire)
    assert_equal [ invitee.id ], @questionnaire.reload.targeted_invitee_ids
    assert_equal [ household.id ], @questionnaire.targeted_household_ids
  end

  test "selected people and households cannot change after a response exists" do
    household = @site.households.create!(name: "Family")
    invitee = @site.invitees.create!(first_name: "Taylor", last_name: "Guest", household:)
    @questionnaire.responses.create!(user: @member, submitted_at: Time.current)

    patch questionnaire_path(@questionnaire), params: {
      questionnaire: {
        title: @questionnaire.title,
        status: "published",
        response_scope: "individual",
        results_visibility: "staff_only",
        group_id: "",
        event_id: "",
        targeted_invitee_ids: [ invitee.id.to_s ],
        targeted_household_ids: []
      }
    }

    assert_redirected_to questionnaire_path(@questionnaire)
    assert_empty @questionnaire.reload.audience_targets
    assert_match "cannot be changed", flash[:alert]
  end

  private

  def sign_in(user)
    post session_path, params: { login_identifier: user.login_identifier, password: "password123" }
  end
end
