require "test_helper"

class InvitationCodeTest < ActiveSupport::TestCase
  test "issued code can be found without storing its plaintext" do
    site = Site.create!(name: "Vowloom test", accent_color: "#8f4f6a")
    household = site.households.create!(name: "The Testers")
    code = InvitationCode.issue_for!(site: site, household: household)

    record = InvitationCode.find_active(site, code)

    assert_equal household, record.household
    assert_not_equal code, record.code_digest
    assert_nil InvitationCode.find_active(site, "NOT-THE-CODE")
  end
end
