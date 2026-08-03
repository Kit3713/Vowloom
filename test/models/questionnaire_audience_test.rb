require "test_helper"

class QuestionnaireAudienceTest < ActiveSupport::TestCase
  setup do
    @site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    @owner = @site.users.create!(display_name: "Owner", login_identifier: "owner-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123", role: :owner)
    @questionnaire = @site.questionnaires.create!(title: "Travel", created_by: @owner, status: :published)
  end

  test "targets must belong to the same wedding site" do
    other_site = Site.create!(name: "Other wedding", accent_color: "#4f6a8f")
    outsider = other_site.invitees.create!(first_name: "Outside", last_name: "Guest")
    target = @questionnaire.audience_targets.build(invitee: outsider)

    assert_not target.valid?
    assert_includes target.errors[:invitee], "must belong to this wedding site"
  end

  test "an explicit audience protects aggregate result visibility and kiosk use" do
    invitee = @site.invitees.create!(first_name: "Taylor", last_name: "Guest")
    unrelated = @site.users.create!(display_name: "Unrelated", login_identifier: "unrelated-#{SecureRandom.hex(4)}", password: "password123", password_confirmation: "password123")
    @questionnaire.audience_targets.create!(invitee:)
    @questionnaire.update!(results_visibility: :aggregate)

    assert_not @questionnaire.results_visible_to?(unrelated)
    assert_not @questionnaire.kiosk_displayable?
    assert_equal "Taylor Guest", @questionnaire.audience_summary
  end
end
