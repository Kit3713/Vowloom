require "test_helper"

class QuestionnaireTemplatesTest < ActiveSupport::TestCase
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
  end

  test "includes the wedding planning templates promised by the questionnaire design" do
    assert_includes QuestionnaireTemplates.keys, "meal_selection"
    assert_includes QuestionnaireTemplates.keys, "rsvp_supplement"
    assert_includes QuestionnaireTemplates.keys, "contact_confirmation"

    questionnaire = @site.questionnaires.create!(title: QuestionnaireTemplates.title_for("meal_selection"), created_by: @owner)
    QuestionnaireTemplates.apply!(questionnaire, "meal_selection")

    assert_equal [ "Your meal", "Dietary needs" ], questionnaire.questions.pluck(:section)
    assert_equal [ "Chicken", "Vegetarian", "Vegan", "Children’s meal" ], questionnaire.questions.first.options
  end
end
