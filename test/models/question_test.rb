require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @questionnaire = @site.questionnaires.create!(title: "Travel", created_by: @owner, status: :published)
    @source = @questionnaire.questions.create!(position: 1, kind: :yes_no, prompt: "Need a ride?")
  end

  test "conditional questions only display when their required answer is present" do
    conditional = @questionnaire.questions.create!(position: 2, kind: :long_text, prompt: "Where should we pick you up?", conditional_rule: { "question_id" => @source.id, "equals" => "yes" })

    assert_predicate conditional, :conditional?
    assert conditional.visible_for?(@source.id => "yes")
    assert_not conditional.visible_for?(@source.id => "no")
  end

  test "choice answers are constrained to configured choices" do
    question = @questionnaire.questions.create!(position: 2, kind: :multiple_choice, prompt: "Pick roles", options: [ "Setup", "Cleanup" ])

    assert question.answer_allowed?([ "Setup", "Cleanup" ])
    assert_not question.answer_allowed?([ "DJ" ])
  end

  test "aggregate results are visible to members while detailed results require explicit permission" do
    member = @site.users.create!(display_name: "Member", login_identifier: "member-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @questionnaire.update!(results_visibility: :aggregate)

    assert @questionnaire.results_visible_to?(member)
    assert_not @questionnaire.individual_results_visible_to?(member)

    @questionnaire.update!(results_visibility: :member_visible)
    assert @questionnaire.individual_results_visible_to?(member)
  end
end
